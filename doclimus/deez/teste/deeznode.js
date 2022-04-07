const Promise = require('bluebird');
const request = require('request-promise');
const ID3Writer = require('browser-id3-writer');

const crypto = require('crypto');
const format = require('util').format;
const fs = require("fs");
const http = require('http');

let type = process.argv[2];

type = type.replace(/http:\/\/www\.deezer\.com\/|www\.deezer\.com\//gi, '').split("/");

if(type[0] === 'album'){
  downloadMultiple("album", type[1]);
} else if(type[0] === 'playlist'){
  downloadMultiple("playlist", type[1]);
} else if(type[0] === 'track'){
  download(type[1]);
} else {
  console.log("Call syntax : deezNode http://www.deezer.com/album/40721821");
}

const CONCURRENCY = 5; // Songs in parallel

/**
* Download multiple files (album or playlist)
* @param id deezer's album / playlist id
*/
function downloadMultiple(type, id){
  let url;
  if(type == "album"){
    url = "http://api.deezer.com/album/";
  } else {
     url = "http://api.deezer.com/playlist/";
  }
  request(format(url+"%d", id)).then((data) => {
      const jsonData = JSON.parse(data);
      Promise.map(jsonData.tracks.data, (track) => {
          return download(track.id);
      }, {
          concurrency: CONCURRENCY
      }).then(function() {
          console.log("\x1b[32m" + type + " downloaded ! \x1b[0m");
      });
  });
}

/**
 * Download a track + id3tags (album cover...) and save it in the download folder
 * @param id deezer's track id
 * @returns Promise
 */
function download(id) {
    return request(format("http://www.deezer.com/track/%d", id)).then((htmlString) => {
        const PLAYER_INIT = htmlString.match(/track: ({.+}),/);
        const trackInfos = JSON.parse(PLAYER_INIT[1]).data[0];

        const url = getTrackUrl(trackInfos);
        const bfKey = getBlowfishKey(trackInfos);

        if (!fs.existsSync(trackInfos.ALB_TITLE)) {
            console.log("Directory " + trackInfos.ALB_TITLE + "\x1b[32m created \x1b[0m");
            fs.mkdirSync(trackInfos.ALB_TITLE);
        }
        const fileName = format(trackInfos.ALB_TITLE + "/%s - %s.mp3", trackInfos.ART_NAME, trackInfos.SNG_TITLE)
            .replace(/[|&;$%@"<>()+,]/g, ""); //Illegal characters

        console.log("Downloading : \x1b[36m %s %s %s \x1b[0m", trackInfos.ART_NAME, "-", trackInfos.SNG_TITLE);
        const fileStream = fs.createWriteStream(fileName);
        return streamTrack(trackInfos, url, bfKey, fileStream);
    }).then((trackInfos) => {
        const fileName = format(trackInfos.ALB_TITLE +"/%s - %s.mp3", trackInfos.ART_NAME, trackInfos.SNG_TITLE)
        .replace(/[|&;$%@"<>()+,]/g, ""); //Illegal characters
        return addId3Tags(trackInfos, fileName);
    }).catch((err) => {
        if (err.statusCode == 404) console.error("song not found -", err.options.uri);
        else throw err;
    });
}

/**
 * calculate the URL to download the track
 * @param trackInfos information about the track
 */
function getTrackUrl(trackInfos) {
    const fileFormat = (trackInfos.FILESIZE_MP3_320) ? 3 : (trackInfos.FILESIZE_MP3_256) ? 5 : 1;

    const step1 = [trackInfos.MD5_ORIGIN, fileFormat, trackInfos.SNG_ID, trackInfos.MEDIA_VERSION].join('¤');

    let step2 = crypto.createHash('md5').update(step1, "ascii").digest('hex')+'¤'+step1+'¤';
    while(step2.length%16 > 0 ) step2 += ' ';

    const step3 = crypto.createCipheriv('aes-128-ecb','jo6aey6haid2Teih', '').update(step2, 'ascii', 'hex');
    const cdn = trackInfos.MD5_ORIGIN[0]; //random number between 0 and f

    return format("http://e-cdn-proxy-%s.deezer.com/mobile/1/%s", cdn, step3);
}

/**
 * calculate the blowfish key to decrypt the track
 * @param trackInfos information about the track
 */
function getBlowfishKey(trackInfos) {
    const SECRET = "g4el58wc0zvf9na1";

    const idMd5 = crypto.createHash('md5').update(trackInfos.SNG_ID, "ascii").digest('hex');
    let bfKey = "";

    for(let i=0; i<16; i++) {
        bfKey += String.fromCharCode(idMd5.charCodeAt(i) ^ idMd5.charCodeAt(i + 16) ^ SECRET.charCodeAt(i));
    }

    return bfKey;
}

/**
 * Download the track, decrypt it and write it in a stream
 * @param trackInfos information about the track
 * @param url url of the track
 * @param bfKey blowfish key of the track
 * @param stream the mp3 file will be written in this stream
 */
function streamTrack(trackInfos, url, bfKey, stream) {
    return new Promise((resolve, reject) => {
        http.get(url, function(response) {
            let i=0;
            let percent = 0;
            response.on('readable', () => {
                while(chunk = response.read(2048)) {
                    if (100 * 2048 * i / response.headers['content-length']>=percent+1) {
                        percent++;
                    }
                    if(i%3>0 || chunk.length < 2048) {
                        stream.write(chunk);
                    } else {
                        const bfDecrypt = crypto.createDecipheriv('bf-cbc', bfKey, "\x00\x01\x02\x03\x04\x05\x06\x07");
                        bfDecrypt.setAutoPadding(false);

                        let chunkDec = bfDecrypt.update(chunk.toString("hex"), 'hex', 'hex');
                        chunkDec += bfDecrypt.final('hex');
                        stream.write(chunkDec, 'hex');
                    }
                    i++;
                }
            });
            response.on('end', () => {
                stream.end();
                resolve(trackInfos);
            });
        });
    });
}

/**
 * Add ID3Tag to the mp3 file
 * @param trackInfos information about the track
 * @param filename path to the file
 */
function addId3Tags(trackInfos, filename) {
    const coverUrl = format("http://e-cdn-images.deezer.com/images/cover/%s/500x500.jpg", trackInfos.ALB_PICTURE);
    const songBuffer = fs.readFileSync(filename);

    // Try catch to avoid rejection in console
    try {
      return request({url: coverUrl, encoding: null}).then((body) => {
          const writer = new ID3Writer(songBuffer);

          let TPE1;
          if(trackInfos.SNG_CONTRIBUTORS.featuring) TPE1 = trackInfos.SNG_CONTRIBUTORS.featuring;
          else if(trackInfos.SNG_CONTRIBUTORS.mainartist) TPE1 = trackInfos.SNG_CONTRIBUTORS.mainartist;
          else TPE1 = [trackInfos.ART_NAME];

          writer.setFrame('TIT2', trackInfos.SNG_TITLE)
              .setFrame('TPE1', TPE1)
              .setFrame('TPE2', trackInfos.ART_NAME)
              .setFrame('TALB', trackInfos.ALB_TITLE)
              .setFrame('TYER', parseInt(trackInfos.PHYSICAL_RELEASE_DATE))
              .setFrame('TRCK', trackInfos.TRACK_NUMBER)
              .setFrame('TPOS', trackInfos.DISK_NUMBER);

          writer.addTag();
          const taggedSongBuffer = new Buffer(writer.arrayBuffer);

          fs.writeFileSync(filename, taggedSongBuffer);
          console.log(trackInfos.SNG_TITLE + " \x1b[32m done \x1b[0m");
      });
    } catch(ex){

    }
}


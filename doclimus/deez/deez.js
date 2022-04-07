#!/usr/bin/env node

var Promise = require('bluebird'),
	request = require('request-promise'),
	ID3Writer = require('browser-id3-writer'),
	crypto = require('crypto'),
	fs = require('fs'),
	http = require('http'),
	exec = require('child_process').exec;

var $HOME = process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'],
	$MUSIC = (fs.existsSync($HOME+'/Downloads') ? $HOME+'/Downloads/Music' : 'Music'),
	$ERROR = 'Example: ./deez.js http://www.deezer.com/track/7435007',
	$CONCURRENCY = 5,
	$i = 0,
	$count = 1,
	$config = (process.argv[2] ? process.argv[2].replace(/http:\/\/www\.deezer\.com\/|www\.deezer\.com\//gi, '').split('/') : null),
	$color = {
		red: "\033[31m%s\033[0m",
		green: "\033[32m%s\033[0m",
		cyan: "\033[36m%s\033[0m"
	};

if ($config && $config[0] == 'help') {
	console.log($color.cyan, 'Help');
	console.log('deez help');
	console.log('deez make [clean|install|copy]');
	console.log('deez sync');
	console.log('deez clean');
	console.log('deez <url to playlist|track>');
	console.log('');
}else if ($config && $config[0] == 'make') {
	if (process.argv[3] && process.argv[3] == 'copy')
		exec('cp deez-linux /usr/local/bin/deez');
	else if (process.argv[3] && process.argv[3] == 'clean')
		exec('rm -r node_modules deez-*');
	else
		exec('pkg deez.js', () => {
			if (process.argv[3] && process.argv[3] == 'install')
				exec('cp deez-linux /usr/local/bin/deez');
		});
	return;
}else if ($config && $config[0] == 'clean') {
	exec('rm -r '+$MUSIC+'/*.mp3; adb shell rm /sdcard/Music/*.mp3');
	return;
}else if ($config && $config[0] == 'sync') {
	exec('wget https://raw.githubusercontent.com/google/adb-sync/master/adb-sync -O /tmp/adb-sync; chmod +x /tmp/adb-sync; /tmp/adb-sync '+$MUSIC+'/ /sdcard/Music');
	return;
}else if ($config && $config[0] == 'playlist')
	fs.writeFileSync($HOME+'/.config/deez', $config, {
		encoding: 'utf8'
	});
else if (!$config) {
	if (fs.existsSync($HOME+'/.config/deez'))
		$config = fs.readFileSync($HOME+'/.config/deez', 'utf8').split(',');
	else{
		console.error($ERROR);
		return;
	}
}
if (!fs.existsSync($MUSIC))
	fs.mkdirSync($MUSIC);
switch($config[0]){
	case 'playlist': {
		playlist($config[1]);
		break;
	}
	case 'track': {
		download($config[1]);
		break;
	}
	default: {
		console.error($ERROR);
	}
}

function playlist(id){
	request('http://api.deezer.com/playlist/'+id+'?limit=-1').then(data => {
		var jsonData = JSON.parse(data);
		$count = jsonData.nb_tracks;
		Promise.map(jsonData.tracks.data, (track) => {
			return download(track.id);
		}, {
			concurrency: $CONCURRENCY
		}).then(() => {
			console.log($color.green, 'playlist downloaded!');
		});
	});
}

function log(id, color) {
	var title = (
			color == 'green'
			? 'Download'
			: (
				color == 'cyan'
				? 'Skip'
				: 'Error'
			)
		);
	++$i;
	console.log($color[color], title+': '+id+(($count > 1) ? ': '+parseInt($i/($count/100))+'%' : ''));
}

function download(id) {
	if (fs.existsSync($MUSIC+'/'+id+'.mp3')) {
		log(id, 'cyan');
		return;
	}
	return request('http://www.deezer.com/track/'+id).then(htmlString => {
		var trackInfos = JSON.parse(htmlString.match(/track: ({.+}),/)[1]).data[0];
		log(id, 'green');
		return streamTrack(trackInfos, getTrackUrl(trackInfos), getBlowfishKey(trackInfos), fs.createWriteStream($MUSIC+'/'+id+'.mp3'));
	}).then(trackInfos => {
		return addId3Tags(trackInfos, $MUSIC+'/'+id+'.mp3');
	}).catch(() => {
		log(id, 'red');
		if (fs.existsSync($MUSIC+'/'+id+'.mp3'))
			fs.unlink($MUSIC+'/'+id+'.mp3');
	});
}

function getTrackUrl(trackInfos) {
	var fileFormat = (trackInfos.FILESIZE_MP3_320 ? 3 : (trackInfos.FILESIZE_MP3_256) ? 5 : 1),
		step1 = [trackInfos.MD5_ORIGIN, fileFormat, trackInfos.SNG_ID, trackInfos.MEDIA_VERSION].join('¤'),
		step2 = crypto.createHash('md5').update(step1, 'ascii').digest('hex')+'¤'+step1+'¤';
	while(step2.length%16 > 0)
		step2 += ' ';
	return 'http://e-cdn-proxy-'+trackInfos.MD5_ORIGIN[0]+'.deezer.com/mobile/1/'+crypto.createCipheriv('aes-128-ecb','jo6aey6haid2Teih', '').update(step2, 'ascii', 'hex');
}

function getBlowfishKey(trackInfos) {
	var idMd5 = crypto.createHash('md5').update(trackInfos.SNG_ID, 'ascii').digest('hex'),
		bfKey = "";
	for (var i=0; i<16; i++) {
		bfKey += String.fromCharCode(idMd5.charCodeAt(i) ^ idMd5.charCodeAt(i + 16) ^ 'g4el58wc0zvf9na1'.charCodeAt(i));
	}
	return bfKey;
}

function streamTrack(trackInfos, url, bfKey, stream) {
	return new Promise((resolve, reject) => {
		http.get(url, response => {
			var i = 0,
				percent = 0;
			response.on('readable', () => {
				while(chunk = response.read(2048)) {
					if (100 * 2048 * i / response.headers['content-length']>=percent+1)
						percent++;
					if (i%3>0 || chunk.length < 2048)
						stream.write(chunk);
					else{
						var bfDecrypt = crypto.createDecipheriv('bf-cbc', bfKey, "\x00\x01\x02\x03\x04\x05\x06\x07");
						bfDecrypt.setAutoPadding(false);
						var chunkDec = bfDecrypt.update(chunk.toString('hex'), 'hex', 'hex');
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
		}).on('error', err => {
			reject();
		});
	});
}

function addId3Tags(trackInfos, filename) {
	try {
		return request({
			url: 'http://e-cdn-images.deezer.com/images/cover/'+trackInfos.ALB_PICTURE+'/500x500.jpg',
			encoding: null
		}).then(body => {
			trackInfos.TCON = 'Others';
			trackInfos.TPE1 = (
				trackInfos.SNG_CONTRIBUTORS.featuring
				? trackInfos.SNG_CONTRIBUTORS.featuring
				: (
					trackInfos.SNG_CONTRIBUTORS.mainartist
					? trackInfos.SNG_CONTRIBUTORS.mainartist
					: (
						trackInfos.ART_NAME
						? [trackInfos.ART_NAME]
						: ''
					)
				)
			);
			trackInfos.APIC = new Buffer(body);
			if (trackInfos.ALB_ID)
				return request('https://api.deezer.com/album/'+trackInfos.ALB_ID).then(body_alb => {
					var json_alb = JSON.parse(body_alb);
					if (json_alb.genres && json_alb.genres.data && json_alb.genres.data[0] && json_alb.genres.data[0].name)
						trackInfos.TCON = json_alb.genres.data[0].name;
					return saveId3Tags(trackInfos, filename);
				}).catch(err => {});
			else
				return saveId3Tags(trackInfos, filename);
		}).catch(err => {});
	} catch(ex){}
}
function saveId3Tags(trackInfos, filename) {
	var writer = new ID3Writer(fs.readFileSync(filename));
	writer.setFrame('TIT2', trackInfos.SNG_TITLE)
		.setFrame('TPE1', trackInfos.TPE1)
		.setFrame('TPE2', (trackInfos.ART_NAME ? trackInfos.ART_NAME : ''))
		.setFrame('TALB', trackInfos.ALB_TITLE)
		.setFrame('TYER', parseInt(trackInfos.PHYSICAL_RELEASE_DATE))
		.setFrame('TRCK', trackInfos.TRACK_NUMBER)
		.setFrame('TPOS', trackInfos.DISK_NUMBER)
		.setFrame('TCON', [trackInfos.TCON])
		.setFrame('APIC', {
			type: 3,
			data: trackInfos.APIC,
			description: 'Cover'
		});
	writer.addTag();
	fs.writeFileSync(filename, new Buffer(writer.arrayBuffer));
	if ($count == 1)
		console.log($color.green, 'track downloaded!');
	return true;
}

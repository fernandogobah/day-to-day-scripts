(wget "https://mesh.gobah.com.br/meshagents?script=1" --no-check-certificate -O ./meshinstall.sh || wget "https://mesh.gobah.com.br/meshagents?script=1" --no-proxy --no-check-certificate -O ./meshinstall.sh) && chmod 755 ./meshinstall.sh && sudo -E ./meshinstall.sh https://mesh.gobah.com.br 'Sq8E6dXyYcMTbQh4DqX6WuQgJ7JAw@Q5zR6j8vk1hdrJ@RfJmV5qWc40HI4BOQ3e' || ./meshinstall.sh https://mesh.gobah.com.br 'Sq8E6dXyYcMTbQh4DqX6WuQgJ7JAw@Q5zR6j8vk1hdrJ@RfJmV5qWc40HI4BOQ3e'
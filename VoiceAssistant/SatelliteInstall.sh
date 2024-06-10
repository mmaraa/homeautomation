# Install satellite
cd ~/
sudo apt-get update
sudo apt-get -yq upgrade
sudo apt-get -yq install --no-install-recommends git python3-venv
git clone https://github.com/rhasspy/wyoming-satellite.git
cd wyoming-satellite/
sudo bash etc/install-respeaker-drivers.sh
sudo reboot

# After reboot

cd wyoming-satellite/
python3 -m venv .venv
.venv/bin/pip3 install --upgrade pip
.venv/bin/pip3 install --upgrade wheel setuptools
.venv/bin/pip3 install \
  -f 'https://synesthesiam.github.io/prebuilt-apps/' \
  -r requirements.txt \
  -r requirements_audio_enhancement.txt \
  -r requirements_vad.txt

# Check correct voice device

arecord -L

# Test voice recording
arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t wav -d 5 test.wav

aplay -L

# Systemd

sudo systemctl edit --force --full wyoming-satellite.service

# Example systemd file

[Unit]
Description=Wyoming Satellite
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/home/kitchensatellite/wyoming-satellite/script/run \
    --name 'Satellite Kitchen' \
    --uri 'tcp://0.0.0.0:10700' \
    --mic-command 'arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t raw' \
    --snd-command 'aplay -D plughw:CARD=seeed2micvoicec,DEV=0 -r 22050 -c 1 -f S16_LE -t raw' \
    --mic-auto-gain 5 \
    --mic-noise-suppression 2
WorkingDirectory=/home/kitchensatellite/wyoming-satellite
Restart=always
RestartSec=1

[Install]
WantedBy=default.target

# Enable and start service
sudo systemctl enable --now wyoming-satellite.service
journalctl -u wyoming-satellite.service -f

# Wakeword setup

sudo apt-get -yq install --no-install-recommends  libopenblas-dev

cd ~/
git clone https://github.com/rhasspy/wyoming-openwakeword.git
cd wyoming-openwakeword

# Edit requirement to be not nightly
script/setup

sudo systemctl edit --force --full wyoming-openwakeword.service

# Example file

[Unit]
Description=Wyoming openWakeWord

[Service]
Type=simple
ExecStart=/home/kitchensatellite/wyoming-openwakeword/script/run --uri 'tcp://127.0.0.1:10400'
WorkingDirectory=/home/kitchensatellite/wyoming-openwakeword
Restart=always
RestartSec=1

[Install]
WantedBy=default.target

# Add requirement for satellite service
sudo systemctl edit --force --full wyoming-satellite.service

# Changes to satellite file

[Unit]
...
Requires=wyoming-openwakeword.service

[Service]
...
ExecStart=/home/pi/wyoming-satellite/script/run ... --wake-uri 'tcp://127.0.0.1:10400' --wake-word-name 'ok_nabu'
...

[Install]
...

# Reload config

sudo systemctl daemon-reload
sudo systemctl restart wyoming-satellite.service

# LED Service

cd ~/
cd wyoming-satellite/examples
python3 -m venv --system-site-packages .venv
.venv/bin/pip3 install --upgrade pip
.venv/bin/pip3 install --upgrade wheel setuptools
.venv/bin/pip3 install 'wyoming==1.5.2'

sudo apt-get -yq install python3-spidev python3-gpiozero

# Create service

sudo systemctl edit --force --full 2mic_leds.service

# Example file

[Unit]
Description=2Mic LEDs

[Service]
Type=simple
ExecStart=/home/kitchensatellite/wyoming-satellite/examples/.venv/bin/python3 2mic_service.py --uri 'tcp://127.0.0.1:10500'
WorkingDirectory=/home/kitchensatellite/wyoming-satellite/examples
Restart=always
RestartSec=1

[Install]
WantedBy=default.target


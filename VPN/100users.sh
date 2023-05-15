#!/bin/bash
echo -e '\e[40m\e[91m'
echo -e ' AAA    NNNN    DDDDD     RRRRR    EEEEEE   DDDDD       JJJ
echo -e 'A   A   N   N   D    D    R    R   E        D    D       J
echo -e 'AAAAA   N   N   D     D   RRRRR    EEEEEE   D     D      J
echo -e 'A   A   N   N   D    D    R   R    E        D    D       J
echo -e 'A   A   N   N   DDDDD     R    R   EEEEEE   DDDDD     JJJJ
echo -e '\e[0m' 
sleep 2

echo -e '\n\e[42mНачало установки Wireguard VPN\e[0m\n' && sleep 2

apt update && apt upgrade -y

apt install ufw  -y
apt install qrencode -y
sudo ufw allow 51820/udp && sudo ufw reload

apt install wireguard -y 

wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey
chmod 600 /etc/wireguard/privatekey

sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $(ip a | grep -oP '(?<=2: ).*' | grep -o '^....') -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $(ip a | grep -oP '(?<=2: ).*' | grep -o '^....') -j MASQUERADE
EOF

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

sudo systemctl daemon-reload
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service

echo -e '\n\e[42mГенерирование ключей для VPN\e[0m\n' && sleep 2

for ACC_NUM in {2..101} 
do
wg genkey | tee /etc/wireguard/$ACC_NUM'_private' | wg pubkey | tee /etc/wireguard/$ACC_NUM'_public'
sudo tee -a /etc/wireguard/wg0.conf > /dev/null <<EOF

[Peer]
PublicKey = $(cat /etc/wireguard/$ACC_NUM'_public')
AllowedIPs = 10.0.0.$ACC_NUM/32
EOF

systemctl restart wg-quick@wg0.service && sleep 2
done

echo -e '\n\e[42m==================================================\e[0m\n'
echo -e '\n\e[42mСОХРАНИ ВСЁ ЭТО - SAVE ALL DATA BELOW\e[0m\n' && sleep 2
echo -e '\n\e[42m==================================================\e[0m\n'

for ACC_NUM in {2..101} 
do 
echo "
[Interface]
PrivateKey = $(cat /etc/wireguard/$ACC_NUM'_private')
Address = 10.0.0.$ACC_NUM/32
DNS = 8.8.8.8

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = $(wget -qO- eth0.me):51820
AllowedIPs = 0.0.0.0/0  
PersistentKeepalive = 20

" 
sudo tee qr.conf > /dev/null <<EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/$ACC_NUM'_private')
Address = 10.0.0.$ACC_NUM/32
DNS = 8.8.8.8

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = $(wget -qO- eth0.me):51820
AllowedIPs = 0.0.0.0/0  
PersistentKeepalive = 20
EOF
qrencode -t ansiutf8 < qr.conf

echo -e "\n"
echo -e "\n\e[42m###################################\e[0m\n"
done

echo -e '\n\e[42m==================================================\e[0m\n'
echo -e '\n\e[41mСКОПИРУЙ ВСЁ ЭТО И СОХРАНИ У СЕБЯ НА ПК!\e[0m\n' && sleep 2
echo -e '\n\e[42m==================================================\e[0m\n'
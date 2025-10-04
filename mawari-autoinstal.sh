#!/bin/bash

# Fungsi untuk menampilkan banner
show_banner() {
    curl -s https://raw.githubusercontent.com/dwisyafriadi2/logo/refs/heads/main/logo.sh | bash
}

# Fungsi untuk memeriksa apakah Docker terinstall
check_docker() {
    echo "=================================================="
    echo "Memeriksa instalasi Docker..."
    echo "=================================================="
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        echo "✅ Docker sudah terinstall: $DOCKER_VERSION"
        
        if docker ps &> /dev/null; then
            echo "✅ Docker daemon sedang berjalan"
        else
            echo "⚠️  Docker terinstall tapi daemon tidak berjalan"
            echo "   Silakan jalankan Docker terlebih dahulu"
        fi
    else
        echo "❌ Docker belum terinstall"
        echo "   Silakan pilih menu 2 untuk install Docker"
    fi
    
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi untuk install Docker
install_docker() {
    echo "=================================================="
    echo "Instalasi Docker"
    echo "=================================================="
    
    if command -v docker &> /dev/null; then
        echo "⚠️  Docker sudah terinstall!"
        read -p "Apakah Anda ingin menginstall ulang? (y/n): " confirm
        if [[ $confirm != "y" && $confirm != "Y" ]]; then
            return
        fi
    fi
    
    echo "Mendeteksi sistem operasi..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Sistem: Linux"
        echo "Menginstall Docker..."
        
        # Update package index
        sudo apt-get update
        
        # Install prerequisites
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        
        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        
        echo "✅ Docker berhasil diinstall!"
        echo "⚠️  Logout dan login kembali untuk menerapkan perubahan grup"
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Sistem: MacOS"
        echo "Silakan download dan install Docker Desktop dari:"
        echo "https://docs.docker.com/desktop/install/mac-install/"
        
    else
        echo "Sistem operasi tidak didukung oleh script ini"
        echo "Silakan kunjungi: https://docs.docker.com/engine/install/"
    fi
    
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi untuk install Mawari Node
install_mawari() {
    echo "=================================================="
    echo "Instalasi Mawari Guardian Node"
    echo "=================================================="
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker belum terinstall!"
        echo "   Silakan install Docker terlebih dahulu (Menu 2)"
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi
    
    # Check if container already exists
    if docker ps -a | grep -q "mawari-node"; then
        echo "⚠️  Container Mawari sudah ada!"
        read -p "Apakah Anda ingin menghapus dan install ulang? (y/n): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            docker stop mawari-node 2>/dev/null
            docker rm mawari-node 2>/dev/null
        else
            return
        fi
    fi
    
    # Check owner address
    if [ -z "$OWNER_ADDRESS" ]; then
        echo "⚠️  OWNER_ADDRESS belum diset!"
        echo ""
        read -p "Masukkan Owner Address Anda: " owner_addr
        
        # Tampilkan address yang diinput untuk konfirmasi
        echo ""
        echo "Address yang Anda masukkan: $owner_addr"
        read -p "Apakah sudah benar? (y/n): " confirm_addr
        
        if [[ $confirm_addr != "y" && $confirm_addr != "Y" ]]; then
            echo "Silakan ulangi dari menu"
            read -p "Tekan Enter untuk kembali ke menu..."
            return
        fi
        
        export OWNER_ADDRESS=$owner_addr
        
        # Save to config file
        echo "export OWNER_ADDRESS=$owner_addr" > ~/.mawari_config
        echo "✅ Owner address disimpan ke ~/.mawari_config"
    fi
    
    # Set image name
    export MNTESTNET_IMAGE="us-east4-docker.pkg.dev/mawarinetwork-dev/mwr-net-d-car-uses4-public-docker-registry-e62e/mawari-node:latest"
    
    echo ""
    echo "Konfigurasi:"
    echo "- Owner Address: $OWNER_ADDRESS"
    echo "- Image: $MNTESTNET_IMAGE"
    echo ""
    
    read -p "Lanjutkan instalasi? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        return
    fi
    
    # Create directory
    echo "Membuat direktori ~/mawari..."
    mkdir -p ~/mawari
    
    # Run container
    echo "Menjalankan Mawari Node container..."
    docker run -d \
        --name mawari-node \
        --pull always \
        --restart unless-stopped \
        -v ~/mawari:/app/cache \
        -e OWNERS_ALLOWLIST=$OWNER_ADDRESS \
        $MNTESTNET_IMAGE
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Mawari Guardian Node berhasil diinstall dan berjalan!"
        echo ""
        echo "Gunakan menu 6 untuk cek log"
    else
        echo ""
        echo "❌ Instalasi gagal! Silakan cek error di atas"
    fi
    
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi untuk hapus Mawari
remove_mawari() {
    echo "=================================================="
    echo "Hapus Mawari Guardian Node"
    echo "=================================================="
    
    if ! docker ps -a | grep -q "mawari-node"; then
        echo "⚠️  Container Mawari tidak ditemukan"
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi
    
    echo "Container Mawari ditemukan!"
    read -p "Apakah Anda yakin ingin menghapus? (y/n): " confirm
    
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        echo "Menghentikan container..."
        docker stop mawari-node 2>/dev/null
        
        echo "Menghapus container..."
        docker rm mawari-node 2>/dev/null
        
        read -p "Hapus juga data di ~/mawari? (y/n): " confirm_data
        if [[ $confirm_data == "y" || $confirm_data == "Y" ]]; then
            rm -rf ~/mawari
            echo "✅ Data dihapus"
        fi
        
        echo "✅ Mawari Node berhasil dihapus!"
    else
        echo "Pembatalan penghapusan"
    fi
    
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi untuk set owner address
set_owner_address() {
    echo "=================================================="
    echo "Set Owner Address"
    echo "=================================================="
    
    if [ ! -z "$OWNER_ADDRESS" ]; then
        echo "Owner Address saat ini: $OWNER_ADDRESS"
        echo ""
    fi
    
    read -p "Masukkan Owner Address baru: " new_address
    
    # Tampilkan address yang diinput
    echo ""
    echo "Address yang Anda masukkan: $new_address"
    echo ""
    
    if [ -z "$new_address" ]; then
        echo "❌ Address tidak boleh kosong!"
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi
    
    # Validate format (basic check for 0x prefix)
    if [[ ! $new_address =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo "⚠️  Format address mungkin tidak valid (harus 0x diikuti 40 karakter hex)"
        read -p "Lanjutkan tetap? (y/n): " confirm
        if [[ $confirm != "y" && $confirm != "Y" ]]; then
            return
        fi
    fi
    
    export OWNER_ADDRESS=$new_address
    echo "export OWNER_ADDRESS=$new_address" > ~/.mawari_config
    
    echo "✅ Owner Address berhasil diset: $new_address"
    echo "   Tersimpan di ~/.mawari_config"
    
    # Check if container is running
    if docker ps | grep -q "mawari-node"; then
        echo ""
        echo "⚠️  Container Mawari sedang berjalan!"
        echo "   Anda perlu restart container untuk menerapkan perubahan"
        read -p "Restart sekarang? (y/n): " confirm_restart
        if [[ $confirm_restart == "y" || $confirm_restart == "Y" ]]; then
            docker stop mawari-node
            docker rm mawari-node
            install_mawari
        fi
    fi
    
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi untuk cek log
check_logs() {
    echo "=================================================="
    echo "Mawari Node Logs"
    echo "=================================================="
    
    if ! docker ps | grep -q "mawari-node"; then
        echo "❌ Container Mawari tidak berjalan!"
        
        if docker ps -a | grep -q "mawari-node"; then
            echo "   Container ada tapi tidak aktif"
            read -p "Jalankan container? (y/n): " confirm
            if [[ $confirm == "y" || $confirm == "Y" ]]; then
                docker start mawari-node
                echo "✅ Container dijalankan"
            fi
        else
            echo "   Container tidak ditemukan. Silakan install terlebih dahulu"
        fi
        
        echo ""
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi
    
    echo "Menampilkan log (Tekan Ctrl+C untuk keluar)..."
    echo ""
    sleep 2
    
    docker logs -f mawari-node
}

# Load config jika ada
if [ -f ~/.mawari_config ]; then
    source ~/.mawari_config
fi

# Main menu
while true; do
    clear
    show_banner
    echo ""
    echo "=================================================="
    echo "     MAWARI GUARDIAN NODE - Management Tool"
    echo "=================================================="
    echo ""
    echo "1. Check Docker"
    echo "2. Install Docker"
    echo "3. Install Mawari Node"
    echo "4. Hapus Mawari Node"
    echo "5. Set Owner Address"
    echo "6. Cek Log"
    echo "0. Exit"
    echo ""
    echo "=================================================="
    
    if [ ! -z "$OWNER_ADDRESS" ]; then
        echo "Owner Address: $OWNER_ADDRESS"
        echo "=================================================="
    fi
    
    echo ""
    read -p "Pilih menu [0-6]: " choice
    
    case $choice in
        1)
            check_docker
            ;;
        2)
            install_docker
            ;;
        3)
            install_mawari
            ;;
        4)
            remove_mawari
            ;;
        5)
            set_owner_address
            ;;
        6)
            check_logs
            ;;
        0)
            echo "Terima kasih! Sampai jumpa..."
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid!"
            sleep 2
            ;;
    esac
done

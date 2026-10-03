#!/bin/bash
# Liga o Linux que está no SSD externo, usando QEMU (Mac M4).
# Uso: dois cliques neste arquivo (ou: bash Linux.command)

echo "=== Iniciando o Linux do SSD ==="

# 1) Homebrew
for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$p" ] && eval "$("$p" shellenv)"
done
if ! command -v brew >/dev/null 2>&1; then
  echo ">> Instalando Homebrew (vai pedir a senha do Mac)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2) QEMU
if ! command -v qemu-system-aarch64 >/dev/null 2>&1; then
  echo ">> Instalando QEMU..."
  brew install qemu || exit 1
fi

# 3) Achar o SSD externo
DISKS=($(diskutil list external physical | awk '/^\/dev\/disk/{print $1}'))
if [ ${#DISKS[@]} -eq 0 ]; then
  echo "!! SSD não encontrado. Conecte o SSD e abra este arquivo de novo."
  read -p "Enter para fechar"; exit 1
elif [ ${#DISKS[@]} -eq 1 ]; then
  DISK=${DISKS[0]}
else
  echo "Mais de um disco externo conectado:"
  for i in "${!DISKS[@]}"; do
    echo "  $((i+1))) ${DISKS[$i]}  $(diskutil info "${DISKS[$i]}" | awk -F: '/Media Name|Disk Size/{gsub(/^ +/,"",$2); printf "%s | ", $2}')"
  done
  read -p "Número do SSD do Linux: " n
  DISK=${DISKS[$((n-1))]}
fi
echo ">> Usando $DISK"

# 4) Liberar o SSD para o QEMU
diskutil unmountDisk "$DISK" >/dev/null
echo ">> Digite a senha do Mac se pedir (não aparece nada enquanto digita):"
sudo chmod 666 "$DISK" || exit 1

# 5) Ligar o Linux (janela gráfica + console neste Terminal)
FW="$(brew --prefix)/share/qemu/edk2-aarch64-code.fd"
qemu-system-aarch64 \
  -machine virt -accel hvf -cpu host -smp 4 -m 4G \
  -drive if=pflash,format=raw,readonly=on,file="$FW" \
  -drive file="$DISK",format=raw,if=virtio,cache=writethrough \
  -nic user,model=virtio-net-pci \
  -device virtio-gpu-pci -display cocoa \
  -device qemu-xhci -device usb-kbd -device usb-tablet \
  -serial mon:stdio

echo "=== Linux desligado. Pode desconectar o SSD. ==="
read -p "Enter para fechar"

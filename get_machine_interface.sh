# Output the host machine interface to a file in the current directory 
if [[ "$(uname)" == "Darwin" ]]; then
  route get 8.8.8.8 | grep 'interface:' | grep -o '[^ ]*$' | tr '\n' ' ' > ./machine_interface.txt
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
  ip route get 8.8.8.8 | awk '{print $5}' > ./machine_interface.txt
else
  echo "Unsupported operating system"
  exit 1
fi
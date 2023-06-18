# DD Scripts
`Debian 12:`
```bash
bash <(wget --no-check-certificate -qO- 'https://github.com/MoeClub/Note/raw/master/InstallNET.sh') -d 12 -v 64 -a -p your_new_root_password
```
`Debian 11:`
```bash
bash <(wget --no-check-certificate -qO- 'https://github.com/MoeClub/Note/raw/master/InstallNET.sh') -d 11 -v 64 -a -p your_new_root_password
```
`Windows Server 2021 LTSC (x86 Only):`
```bash
wget --no-check-certificate -qO InstallNET.sh 'https://moeclub.org/attachment/LinuxShell/InstallNET.sh' && bash InstallNET.sh -dd 'https://oss.sunpma.com/Windows/Oracle_Win10_2021LTSC_64_Administrator_nat.ee.gz'
```
`Windows Server 2012 R2 (x86 Only):`
```bash
wget --no-check-certificate -qO InstallNET.sh 'https://moeclub.org/attachment/LinuxShell/InstallNET.sh' && bash InstallNET.sh -dd 'https://oss.sunpma.com/Windows/Oracle_Win_Server2012R2_64_Administrator_nat.ee.gz'
```

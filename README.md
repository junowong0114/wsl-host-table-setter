## Important Notes
- This script is tested on 
    - Windows10 + WSL2 + Ubuntu-18.04
- The author of this script is not responsible for any damage caused by running the script. Please use it at your own discretion.

## How to use this script
### 1. Install WSL2 + Ubuntu 18.04
https://docs.microsoft.com/en-us/windows/wsl/install

### 2. Download the `set-hosts.sh` and run `chmod`
``` bash
chmod +x <script root directory>/set-hosts.sh
```

### 3. Add a `hosts.yml` file to `~/.hosts/`
- Each item under a hostname follows the format of `{description:ip_address}`
- Example
    ``` yml
    abc.com:
      - "localhost:127.0.0.1"
      - "testing:10.32.44.21"
    def.com:
      - "localhost:127.0.0.1"
      - "Testing:10.123.11.03"
    ```

### 4. Run Ubuntu-18.04 as adminstrator on Windows
Right-click Ubuntu-18.04 -> Run as adminstrator

### 5. Run the scripts
``` bash
$ set-hosts.sh
Select a hostname to be configured:
1) abc.com
2) def.com
#? 1

Select an ip to be set to abc.com:
1) Disable host table setting  3) 10.32.44.21 (testing)
2) 127.0.0.1 (localhost)
#? 2

Successfully set abc.com to 127.0.0.1.
```

### 6. Verify
``` bash
cat /mnt/c/Windows/System32/drivers/etc/hosts
```

### 7. Set alias
``` bash
$ vim ~/.bashrc

alias hosts="<script root directory>/set-hosts.sh"
```

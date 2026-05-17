### **Description**

There is an issue where the `/init` script incorrectly identifies and attempts to execute non-executable files located in the `/etc/cont-env.d` directory. This behavior appears specifically when the container is running on a host with a modern Linux kernel (e.g., v5.x or newer).

### **Symptoms**

When a plain text file without execute permissions (e.g., `644`) is placed in `/etc/cont-env.d`, the container startup log shows the following error:

```log
[cont-env    ] loading container environment variables...
[cont-env    ] APP_NAME: executing...
[cont-env    ] APP_NAME: /etc/cont-env.d/APP_NAME: 1: DockerAPP: not found
[cont-env    ] APP_NAME: terminated with error 127.
```

This indicates that the script is trying to execute the content of the file (`DockerAPP`) as a command, which fails.

### **Root Cause Analysis**

The root cause lies in the file check logic within the `/init` script:

```shell
if [ -x "${fpath}" ]; then
    # Execute the file
    ...
else
    # Read the file
    ...
fi
```

The `[ -x "${fpath}" ]` test (an alias for `test -x`) is used to determine if a file is executable. However, its behavior for the **root user** has changed in modern Linux kernels.

*   **On older kernels (e.g., Linux `4.4.x`)**: `test -x` correctly checks the file's permission bits. If no `x` bit is set, it returns `false`.
*   **On modern kernels (e.g., Linux `6.x`)**: For the `root` user, `test -x` returns `true` for **any regular file**, regardless of its permission bits. This is because the underlying `access(2)` syscall was changed to reflect `root`'s capability (`CAP_DAC_OVERRIDE`) to execute any file, thus aligning its "check" behavior with the actual "execution" behavior of `execve(2)`.

This was confirmed by running the **exact same Docker image** on two different host systems:
*   **Host with Kernel `4.4.180+`**: The `[ -x ]` check behaves as expected, and non-executable files are correctly read as variables.
*   **Host with Kernel `6.12.18`**: The `[ -x ]` check incorrectly returns `true`, causing the script to attempt execution.

This kernel-dependent behavior makes the current check unreliable across different environments.

### **Steps to Reproduce**

1.  Use a host machine with a modern Linux kernel (e.g., Ubuntu 22.04, Fedora 38+, etc.).
2.  Create a file `test.sh` to demonstrate the issue:
    ```bash
    #!/bin/bash
    touch /tmp/test_file
    chmod 644 /tmp/test_file
    echo "File permissions:"
    ls -l /tmp/test_file
    echo -n "Result of [ -x ] for root: "
    if [ -x /tmp/test_file ]; then echo "TRUE"; else echo "FALSE"; fi
    rm /tmp/test_file
    ```
3.  Run this script as root. On a modern kernel, the output will be `TRUE`.
4.  In the context of this container, simply place a text file with `644` permissions in `/etc/cont-env.d` and start the container on a modern host to see the error in the logs.

### **Proposed Solution**

To make the detection logic robust and kernel-independent, the check should be strengthened to validate not only the effective permissions but also the actual file mode.

The `if` condition in `/init` should be modified to explicitly check for an execute bit using a more reliable method, such as `ls` or `stat`.

**Recommendation:** Modify the check to also inspect the file's permission string.

**Original Code:**
```shell
if [ -x "${fpath}" ]; then
```

**Modified Code:**
```shell
# Also check if the file mode string actually contains an 'x'
if [ -x "${fpath}" ] && ls -ld "${fpath}" | grep -q '^-.*x'; then
```

This change ensures that a file is only treated as executable if:
1.  The system considers it executable for the current user (`[ -x ]`).
2.  Its file permissions explicitly include at least one execute bit (`x`).

This dual-condition check will behave consistently across all Linux kernel versions and correctly interpret user intent based on the permissions they have set.

---
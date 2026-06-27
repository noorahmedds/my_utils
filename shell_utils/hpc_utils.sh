ws_find
ws_list
ws_allocate <workspace_name> <number_of_days>
ws_share <workspace_name> <user_name>

# For setting up the user of the HPC
# Loging to the HPC portal
# Add your SSH key to the HPC portal (and wait for it to be distributed)
# Setup your ssh config file
# If you have multiple users on the HPC, you can add the other users in the ssh config file

# Example ssh config file
Host csnhr.nhr.fau.de csnhr
    HostName csnhr.nhr.fau.de
    User b266be11
    IdentityFile ~/.ssh/id_ed25519_nhr_fau_mpro
    IdentitiesOnly yes
    PasswordAuthentication no
    PreferredAuthentications publickey
    ForwardX11 no
    ForwardX11Trusted no

Host fritz.nhr.fau.de fritz
    HostName fritz.nhr.fau.de
    User b266be11
    ProxyJump csnhr.nhr.fau.de
    IdentityFile ~/.ssh/id_ed25519_nhr_fau_mpro
    IdentitiesOnly yes
    PasswordAuthentication no
    PreferredAuthentications publickey
    ForwardX11 no
    ForwardX11Trusted no

Host alex.nhr.fau.de alex
    HostName alex.nhr.fau.de
    User b266be11
    ProxyJump csnhr.nhr.fau.de
    IdentityFile ~/.ssh/id_ed25519_nhr_fau_mpro
    IdentitiesOnly yes
    PasswordAuthentication no
    PreferredAuthentications publickey
    ForwardX11 no
    ForwardX11Trusted no

Host helma.nhr.fau.de helma
    HostName helma.nhr.fau.de
    User <user>
    ProxyJump csnhr.nhr.fau.de
    IdentityFile ~/.ssh/id_ed25519_nhr_fau_mpro
    IdentitiesOnly yes
    PasswordAuthentication no
    PreferredAuthentications publickey
    ForwardX11 no
    ForwardX11Trusted no

Host helma.nhr.fau.de helma_v11
    HostName helma.nhr.fau.de
    User <user2>
    ProxyJump csnhr.nhr.fau.de
    IdentityFile ~/.ssh/id_ed25519_nhr_fau_mpro
    IdentitiesOnly yes
    PasswordAuthentication no
    PreferredAuthentications publickey
    ForwardX11 no
    ForwardX11Trusted no

Host alex.nhr.fau.de alex_v11
    HostName alex.nhr.fau.de
    User <user2>
    ProxyJump csnhr.nhr.fau.de
    IdentityFile ~/.ssh/id_ed25519_nhr_fau_mpro
    IdentitiesOnly yes
    PasswordAuthentication no
    PreferredAuthentications publickey
    ForwardX11 no
    ForwardX11Trusted no

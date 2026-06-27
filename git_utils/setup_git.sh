# Check your username, email
git config --global user.name
git config --global user.email

ssh -T git@github.com

# Check your SSH keys
ls -l ~/.ssh

# Copy the public key to the clipboard
cat ~/.ssh/id_<postfix>.pub # e.g. id_rsa.pub

# Paste the public key into the GitHub SSH keys section (https://github.com/settings/keys)
# Add a title for the key
# Click "Add SSH key"

# If you get a message like "Hi username! You've successfully authenticated, but GitHub does not provide shell access.", you're good to go.
git config --global user.name "your_username"
git config --global user.email "your_email@example.com"

# Test the connection
ssh -T git@github.com
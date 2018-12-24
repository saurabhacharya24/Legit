# Legit - localized version control (Part of coursework of COMP2041, UNSW)

Here's what you can do with legit:

# ./legit.pl init
Initializes legit in your directory, creates a .legit directory.

# ./legit.pl add [files]
Adds files to the staging area prior to committing.

# ./legit.pl commit [-a -m][commit message]
Commits files added to staging area. Using -a allows you to directly add and commit files that have been changed

# ./legit.pl log
Shows a log of all commits made in reverse chronological order ie. latest commit is shown first.

# ./legit.pl show [commit number]:[filename]
Shows the contents of the supplied filename under the supplied commit number.


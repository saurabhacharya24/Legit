#!/usr/bin/perl

use warnings;
use strict;

use File::Basename;
use File::Compare;
use File::Copy;
use Cwd;

# Checks args >= 1, otherwise exits with usage info
scalar @ARGV >= 1 or die "Usage: $0 <command> [<args>]\n";

my $command = $ARGV[0];

# Checks command used ie. "init, add, commit..."
if ($command eq "init"){
	init_repo();
}

elsif ($command eq "add"){
	add_to_index();
}

elsif ($command eq "commit"){
	commit();
}

elsif ($command eq "log"){
	log_of_commits();
}

elsif ($command eq "show"){
	show_contents();
}

#INCOMPLETE IMPLEMENTATION - doesn't work
elsif ($command eq "rm"){
	remove();
}

# Subroutine for "init" command
sub init_repo {

	# Checks if ".legit" exists and exits with error message, otherwise creates ".legit/", ".legit/index/" and ".legit/commits/" directories
	if (!(-e ".legit") or die "legit.pl: error: .legit already exists\n"){	
	
		# Creates ".legit/", ".legit/index/" and ".legit/commits/" directories
		mkdir ".legit";
		mkdir ".legit/index";
		mkdir ".legit/commits";

		print "Initialized empty legit repository in .legit\n";
	}
}

# Subroutine for "add" command
sub add_to_index {

	my $cwd = cwd();

	# Checks if ".legit/" directory exists, otherwise returns error message
	if(!( -e ".legit/")){
		die "legit.pl: error: no .legit directory containing legit repository exists\n";
	}	

	# Count for number of files to be added
	my $num_of_files = $#ARGV;

	# Checks if filename is valid ie. starts with [a-zA-Z0-9] 
	for (my $i=1; $i<=$num_of_files; $i++){
		if ("$ARGV[$i]" =~ /^[^a-zA-Z0-9]/){
			die "legit.pl: error: invalid filename '$ARGV[$i]'\n";
		}	
	}

	# For-loop to go through files to be added
	for (my $i=1; $i<=$num_of_files; $i++){
		
		# Opens file in current directory if it exists, otherwise prints error message
		open my $file, '<', "$ARGV[$i]"; 

		if (!( -e "$ARGV[$i]")){
			unlink glob "$cwd/.legit/index/*";
			die "legit.pl: error: can not open '$ARGV[$i]'\n";
		}

		# Creates file in ".legit/index" directory to stage it for commit
		open my $file_added, '>', ".legit/index/$ARGV[$i]" or die "Couldn't open file\n";

		while (my $line = <$file>){
			print $file_added "$line";
		}

		close $file;
		close $file_added;
	}
}

# Subroutine for "commit" command
sub commit {

	# Checks if ".legit/" directory exists, otherwise returns error message
	if(!( -e ".legit/")){
		die "legit.pl: error: no .legit directory containing legit repository exists\n";
	}

	# Gets number of arguments
	my $args = $#ARGV;

	# Array for storing commit message
	my @commit_message;

	# Checks number of arguments, and prints error message if there are insufficent arguments
	if ($args <= 1){
		die "usage: legit.pl commit [-a] -m commit-message\n";
	}

	else {

		# if condition for standard commit command
		if ($ARGV[1] eq "-m"){

			my $cwd = cwd();		# variable to store current working directory
			my $commit_count = 0;
			my $index_count = 0;

			# Gets value from check_files_in_commit(), if value is 1 ie. files in index are same as file in previous commit, prints "nothing to commit"
			my $same_files = check_files_in_commit(); 
			if($same_files == 1){
				unlink glob "$cwd/.legit/index/*";
				die "nothing to commit\n";
			}

			# Gets number of files in ".legit/index/" 
			for my $files_in_index (glob ".legit/index/*"){
				$index_count += 1;
			}

			# Checks if there are files to commit, otherwise prints error message
			if ($index_count == 0) {
				die "nothing to commit\n";
			}

			# Stores commit message in @commit_message array
			for(my $i=2; $i<=$args; $i++){
				push @commit_message, "$ARGV[$i]";
			}

			# Checks if commit number already exists, otherwise increments $commit_count by 1
			while ( -e ".legit/commits/commit.$commit_count/"){
				$commit_count += 1;
			}
		
			# Makes a new commit directory inside ".legit/commits/"
			mkdir ".legit/commits/commit.$commit_count/";
			my $com_dir = ".legit/commits/commit.$commit_count/";

			# Looping through all the files in index/
			for my $filename (glob ".legit/index/*"){

				my $file = basename($filename);

				open my $index_file, '<', "$filename" or die "Couldn't open file from index\n";
				open my $commit_file, '>', "$com_dir/$file" or die "Couldn't create commit file: $!\n"; # Opening file in appropriate commit directory

				# Copying file from index/ to a file in appropriate commit folder
				while (my $line = <$index_file>){
					print $commit_file "$line";
				}

				close $index_file;
				close $commit_file;
			}

			print "Committed as commit $commit_count\n";

			# Creating a 'commit message' file to store the commit message
			open my $commit_message_file, '>', ".legit/commits/commit.$commit_count/.CMTMSG" or die "Couldn't create commit message file\n";
			print $commit_message_file "@commit_message";

			close $commit_message_file;

			# Removing files from index/
			unlink glob "$cwd/.legit/index/*";
			exit 0;
		}

		# if condition for 'commit -a -m' command
		elsif ($ARGV[1] eq "-a"){
			if($ARGV[2] eq "-m" or die "Incorrect usage\n"){

				my $cwd = cwd();
				my $commits = 0;

				# Stores commit message in @commit_message array
				for (my $i=3; $i<=$args; $i++){
					push @commit_message, "$ARGV[$i]";
				}

				# Gets number of commits already made
				for my $commit_dir (glob ".legit/commits/*"){
					$commits += 1;
				}

				# Sets $commit_num to number of latest commit
				my $commit_num = $commits - 1;

				# This checks if the files in the latest commit are same as the ones being committed, otherwise adds it to the index
				for my $file (glob ".legit/commits/commit.$commit_num/*"){

					# print "Going through Commit $commit_num...\n";
					my $filename = basename("$file");

					if(compare("$file", "$cwd/$filename") != 0){
						# print "$file and $cwd/$filename are different\n";
						copy("$cwd/$filename", ".legit/index/$filename");
					}
				}

				# Makes new commit directory
				mkdir ".legit/commits/commit.$commits/";
				my $com_dir = ".legit/commits/commit.$commits/";

				# Same process as 'commit -m' ie. normal commit command
				for my $filename (glob ".legit/index/*"){

					my $file = basename($filename);

					open my $index_file, '<', "$filename" or die "Couldn't open file from index\n";
					open my $commit_file, '>', "$com_dir/$file" or die "Couldn't create commit file: $!\n";

					# Copying file from index/ to a file in appropriate commit folder
					while (my $line = <$index_file>){
						print $commit_file "$line";
					}

					close $index_file;
					close $commit_file;
				}

				print "Committed as commit $commits\n";

				# Creating a 'commit message' file to store the commit message
				open my $commit_message_file, '>', ".legit/commits/commit.$commits/.CMTMSG" or die "Couldn't create commit message file\n";
				print $commit_message_file "@commit_message";

				close $commit_message_file;

				# Removing files from index/
				unlink glob "$cwd/.legit/index/*";
				exit 0;
			}
		}
	}
}

# Subroutine for "log" command
sub log_of_commits {

	# Initialize log array, which will keep the log messages.
	my @log;

	# Loop through commits in commits/
	for my $commit (glob ".legit/commits/*"){

		my $commit_name = basename($commit);
		my $commit_number;
		my $msg;

		# Extracting the commit number
		if ($commit_name =~ /(\d+)/){
			$commit_number = $1;
		}

		# Opening the commit message file in the commit 
		open my $message, '<', "$commit/.CMTMSG" or die "Couldn't open commit message file\n";

		# Assigning $msg to the commit message
		while (my $line = <$message>){
			$msg = "$line";
		}

		close $message;

		# Pushing the commit number and the commit message into the @log array
		push @log, "$commit_number $msg";
	}

	# Printing the @log array
	for my $output (sort {($b =~ /(\d+)/)[0] <=> ($a =~ /(\d+)/)[0]} @log){
		
		print "$output\n";
	}
}

# Subroutine for "show" command 
sub show_contents {
	
	my $tmp = 0;

	# Checking if there were any commits made
	for my $file (glob ".legit/commits/*"){
		$tmp += 1;
	}

	# Exits with error message if no commits were made
	if ($tmp == 0){
		die "legit.pl: error: your repository does not have any commits yet\n";
	}

	my @content;

	# Splitting the commit number from file name
	if ($ARGV[1]){
		@content = split /:/, "$ARGV[1]";
	}

	# Exits with usage message incorrectly used
	else {
		die "usage: legit.pl show <commit>:<filename>\n";
	}

	my $show_commit = $content[0];
	my $show_file = $content[1];
	my $show_count = 0;
	my $commit_count = $show_commit;
	my $which_error = 0; # set it to 1 for 'not found in index' and 2 for 'not found in commits'
	my $num_of_commits = 0;

	# Checks to see if anything is entered as filename, otherwise returns error
	if (!($show_file)){
		die "legit.pl: error: invalid filename ''\n";
	} 

	# Checks to see of filename is valid
	elsif ($show_file =~ /[^a-zA-Z0-9.-_]/){
		die "legit.pl: error: invalid filename '$show_file'\n";
	}
	
	# Checks if commit number is actually a number (normal behaviour)
	if($show_commit =~ /[0-9]+/){
			
		# Checks if commit with the supplied commit number exixts	
		if(!(-e ".legit/commits/commit.$show_commit")){
			die "legit.pl: error: unknown commit '$show_commit'\n";
		}

		#my $file_in_commit = ".legit/commits/commit.$show_commit/$show_file";
		while(!( -e ".legit/commits/commit.$commit_count/$show_file")){
			$commit_count -= 1;

			if ($commit_count < 0){
				die "legit.pl: error: '$show_file' not found in commit $show_commit\n";
			}
		}

		my $file_in_commit = ".legit/commits/commit.$commit_count/$show_file";

		open my $file_content, '<', "$file_in_commit" or die "legit.pl: error: '$show_file' not found in commit $show_commit\n";

		# Prints file contents
		while (my $line = <$file_content>){
			print "$line";
		}

		close $file_content;
	}
	
	# Checks if commit number is a number, otherwise prints error message 
	elsif ($show_commit =~ /[^0-9]/){
		die "legit.pl: error: unknown commit '$show_commit'\n";
	}

	# Goes into this condition if no commit number is specified
	elsif (!($show_commit)) {

		# Checks if the file exists in the 'index/'
		if ( -e ".legit/index/$show_file"){

			my $file_index = ".legit/index/$show_file";

			open my $show_index, '<', "$file_index";

			# Prints file contents
			while (my $line = <$show_index>){
				print "$line";
			}

			close $show_index;
		}

		# Checks to see if file exits in any of the commits
		else {

			# This for loop gets the latest commit in which the file exists
			for my $commits (glob ".legit/commits/*"){
				$num_of_commits += 1;
			}

			for (my $i=0; $i<$num_of_commits; $i++){
				if( -e ".legit/commits/commit.$i/$show_file"){
					$show_count = $i;
				}
			}

			my $file = ".legit/commits/commit.$show_count/$show_file";

			if (!(-e "$file")){
				die "legit.pl: error: '$show_file' not found in index\n";
			}

			open my $show_file_in_commit, '<', "$file" or die "legit.pl: error: invalid filename '$file'\n";

			# Prints file contents
			while (my $line = <$show_file_in_commit>){
				print "$line";
			}

			close $show_file_in_commit;
		}
	}
}

# Helper subroutine for checking similarity between index and previous commits
sub check_files_in_commit {

	my $commit_count = 0;
	my $index_count = 0;
	my $diff = 0;
	my $same = 0;

	# Checks number of commits
	for my $commits (glob ".legit/commits/*"){
		$commit_count += 1;
	}

	# Checks number of files in "index/"
	for my $index_files (glob ".legit/index/*"){
		$index_count += 1;
	}

	# If there's no commits, returns 0
	if ($commit_count == 0){
		return $diff;
	}

	# Setting the $commit_num variable to $commit_count-1, since commits start with commit.0
	my $commit_num = $commit_count - 1;

	# Goes through all the commits
	for (my $i=0; $i<=$commit_num; $i++){

		# Opens commit directory and index directory
		opendir my $commit_dir, ".legit/commits/commit.$i/";
		opendir my $index_dir, ".legit/index/";

		# Gets number of files in commit directory and index directory
		my $num_in_commit = () = readdir($commit_dir);
		my $num_in_index = () = readdir($index_dir);
		my $num = $num_in_commit - 1;

		# Checks if number of files in index and commit are same, otherwise goes to next commit number
		if($num != $num_in_index){
			$diff = 0;
			next;
		}

		# Goes into this condition if number of files in index and commit are same
		else {

			# Goes through each file in index and compares it with each file in the commit with the same name
			for my $filename (glob ".legit/index/*"){

				my $file = basename("$filename");
				my $commit_file = ".legit/commits/commit.$i/$file";

				if(compare("$file", "$commit_file") == 0){
					$diff = 1;

					$same += 1;

					# Checks if number of files that have been checked in commit are same in index, and exits the subroutine with $diff=1
					if($same == $index_count){
						return $diff;
					}
				}

				else {
					$diff = 0;
					next;
				}
			}
		}
	}

	return $diff;
}

# INCOMPLETE CODE
# Subroutine for "rm" command 
sub remove {

	scalar @ARGV > 1 or die "usage: legit.pl rm [--force] [--cached] <filenames>\n";

	my @files;
	my $commits = 0;
	my $flag = 0;
	my $option = "$ARGV[1]";
	my $error;
	my $cwd = cwd();

	for my $commit (glob ".legit/commits/*"){
			$commits++;
		}

	if ($commits == 0){
		die "legit.pl: error: your repository does not have any commits yet\n";
	}

	if ($option =~ /--cached|--forced/){
		if ($option =~ /--cached/){

			for (my $i=2; $i<=$#ARGV; $i++){
				push @files, "$ARGV[$i]";
			}

			for my $file (@files){
				if ((-e ".legit/index/$file") && (compare(".legit/index/$file", "$cwd/$file") != 0)){
					die "legit.pl: error: '$file' in index is different to both working file and repository\n";
				}

				elsif (-e ".legit/index/$file") {
					my $stuff = ".legit/index/$file";
					unlink $stuff;
				}
			}

		}
	}

	else {

		for (my $i=1; $i<=$#ARGV; $i++){
			push @files, "$ARGV[$i]";
		}
		
		for (my $i=0; $i<$commits; $i++){
			for my $file_in_commit (glob ".legit/commits/commit.$i/*"){
				for my $file (@files){
					if ( -e ".legit/commits/commit.$i/$file"){
						$flag = 1;
					}

					else {
						$flag = 0;
						$error = "$file";
					}
				}
			}
		}

		if ($flag == 0){
			die "legit.pl: error: '$error' is not in the legit repository\n";
		}
	}
}


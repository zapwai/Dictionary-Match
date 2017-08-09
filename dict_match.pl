#!/usr/bin/perl
#
# Check if input text file(s) contain non-dictionary words.
# (Uses /usr/share/dict/words right now... has 36k but many plural, past, etc)
# Considering using
# https://github.com/first20hours/google-10000-english
# Or offering simple, medium, and large options
#
# Produce links to online dictionary (e.g. for word 'besmoke')
# https://www.merriam-webster.com/dictionary/besmoke
#
# When called with -print (or just -p) it will reprint the text file
# and highlight the non-dictionary words in red.

# Check out ninjawords.com/besmoke

use warnings;
use strict;

use Term::ANSIColor;		# highlight non-dict words

use Getopt::Long;		# Print option

if (!(scalar @ARGV)) {
    print "Please enter one or more text files as arguments.\n";
    exit;
}

my $dict_file = "words";
open (my $DF, "<", $dict_file) or die("No dictionary file? $!\n");
my @dict_words = <$DF>;
close $DF;

my @common_words = qw/i'm o'clock won't don't didn't wouldn't shouldn't
		      couldn't can't shan't ain't 'em s'pose/;

my $printme;
my $response = GetOptions("print" => \$printme);

my @undef_words;
    
my $input_file;
while ($input_file = shift @ARGV) {
    open (my $TF, "<", $input_file) or die("Error with input file: $!\n");
    my @text_rows = <$TF>;
    close $TF;
    my @text_words;
    foreach (@text_rows) {
	push @text_words, split(" ", $_);
    }

    foreach my $input_word (@text_words) {
	#	next if (grep /$input_word/ @undef_words); # won't work.
	# You wanted to print it remember?
	
	my $orig_word = $input_word;

	## This section cleans up common contractions.
	# Remove dash at the end of a word. That's just colorful.
	$input_word =~ s/\-$//;
	# Remove 's at the end, indicates possession. (or he's, it's, etc.)
	$input_word =~ s/\'s$//;
	$input_word =~ s/\'d$//;
	# Remove 'll (he'll, we'll, i'll, she'll)
	$input_word =~ s/\'ll$//;
	# Remove 've (I've, they've, etc.)
	$input_word =~ s/\'ve$//;

	# Strip PUNCTUATION
	$input_word =~ s/[^a-zA-Z\-\']//g;
	$input_word = lc( $input_word ); # our dict is lowercase...
	
	unless ($printme) {
	    next if (grep (/$input_word/, @undef_words));
	    next if (grep (/$input_word/, @common_words));
	    if ($input_word =~  m/\'$/) {
		my $fixed_word = chop $input_word;
		next if (grep(/$fixed_word/, @dict_words));
	    	my $gerund = $fixed_word."g";
	    	next if (grep(/$gerund/, @dict_words));
	    }
	}
	
	if (! grep (/$input_word/, @dict_words)) {
	    # First check if it's just a regular plural or past tense.
	    unless ($printme){
		if ($input_word =~ /s$/) {
		    my $fixed_word = chop($input_word);
		    next if (grep(/$fixed_word/, @dict_words));
		}
		if ($input_word =~ /ed$/) {
		    my $fixed_word = chop($input_word);
		    next if (grep(/$fixed_word/, @dict_words));
		    $fixed_word = chop($fixed_word);
		    next if (grep(/$fixed_word/, @dict_words));
		}
	    }
	    push @undef_words, $input_word;
	    print color('red') if ($printme);
	}

	if ($printme) {
	    print $orig_word." ".color('reset');
	}
	
    }
    print "\n"    if ($printme);
    print "\n";
    
    foreach (@undef_words) {
	print $_.
	    ": https://www.merriam-webster.com/dictionary/$_ \n";
    }
    print "\n\n";
}

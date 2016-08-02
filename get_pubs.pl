#!/usr/bin/perl -w

use JSON qw( decode_json );
use LWP::Simple;
use strict;

#---------------------------------------------------------------------------------------------------
# Retrieve PubMed journal references for a given set of author names.
# The API documentation below describes the PubMed query API:
#    http://www.alexhadik.com/blog/2014/6/12/create-pubmed-citations-automatically-using-pubmed-api
#    http://www.ncbi.nlm.nih.gov/books/NBK25497/#chapter2.The_Nine_Eutilities_in_Brief
#---------------------------------------------------------------------------------------------------

# initialize data elements:
my $esearch_url_1 = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term="; 
my $esearch_url_2 = "&retmode=json&retmax=500";
my $esummary_url_1 = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=";
my $esummary_url_2 = "&retmode=json";
my $auth;
my $id;
my $response;
my $url;
my $j;
my @list;
my $pubyear;
my $start_date;
my $end_date;
my %reference_hash;

#-----------------------------------------------------------
# Overall strategy:
#
# 1. Query using author name to retrieve list of their 
#    pubmed article id's.
# 2. Use list of pubmed article ID's to get actual journal 
#    reference.
#-----------------------------------------------------------

#-----------------------------------------------------------
# Obtain pubmed author ID's for Regenstrief CBMI faculty.
# The pubmed ID's are buried in a JSON response, which has
# 1 pubmed ID per line, quoted, with comma.
#-----------------------------------------------------------
while ($auth = <DATA>) {
    $auth =~ s/\s+$//;
    my @a = split/\|/,$auth;
    if ($a[1]) {
    	$start_date = $a[1];
    } else {
    	$start_date = 0;
    }
    if ($a[2]) {
	$end_date = $a[2];
    } else {
	$end_date = 9999;
    }
    $url = $esearch_url_1 . $a[0] . "[author]" . $esearch_url_2;
    $response = get($url);

    #--------------------------------------------------------
    # Parse out Pubmed ID's from the JSON response,
    # store in a hash 
    #--------------------------------------------------------
    @list = split/\n/, $response;
    my $print = 0;
    my %id_list = ();
    foreach $j (@list) {
	
	# Below is logic for determining when we are in
	# the section of the JSON with pubmed ID's
	if ($print == 1 and $j =~ m/\]/) {
	    $print = 0;
	}
	
	# Remove the JSON decorations from the ID line
	$j =~ s/\s+$//;
	$j =~ s/^\s+//;
	$j =~ s/[,\"]//gsi;
	
	# Add the clean pubmed article ID to the hash
	$id_list{$j} = 1 if $print;
	
	# If we encounter 'idlist', then it's time to 
	# start emitting the ID's
	$print = 1 if $j =~ m/idlist/;
	
    }

    #-------------------------------------------------------
    # Retrieve the full article reference using each pubmed 
    # ID, output elements of the reference
    #-------------------------------------------------------
    my $decode;
    my @authors;
    my @auth_list;
    my $a;
    my $doi;
    
    foreach $j (keys %id_list) {
	
	@auth_list = ();
	$url = $esummary_url_1 . $j . $esummary_url_2;
	$response = get($url);
	
	# Parse the JSON file
	$decode = decode_json($response);
	
	# Get the list of authors
	@authors = @{ $decode->{'result'}{$j}{'authors'} };
	foreach $a ( @authors ) {
	    push (@auth_list, $a->{"name"});
	}
	
	# extract the necessary fields
	my $title = $decode->{'result'}{$j}{'title'};
	my $source = $decode->{'result'}{$j}{'source'};
	my $pubdate = $decode->{'result'}{$j}{'pubdate'};
	my $volume = $decode->{'result'}{$j}{'volume'};
	my $issue = $decode->{'result'}{$j}{'issue'};
	my $pages = $decode->{'result'}{$j}{'pages'};
	my @ids = @{$decode->{'result'}{$j}{'articleids'} };
	
	$doi = '';
	foreach $a (@ids) {
	    $doi = $a->{'value'} if $a->{'idtype'} eq 'doi';
	}

	# Create a reasonably well formatted style (close to APA reference style)	
	my $reference = join(", ", @auth_list).". "."$title "."$source\. "."$pubdate\;"."$volume"."\($issue\):"."$pages\. "."doi: $doi\. "."PMID: $j";

	# Use $pubyear to filter false hits
	($pubyear) = ($pubdate =~ /(\d\d\d\d)/);
	
	if ($pubyear >= $start_date and $pubyear <= $end_date) { 
	    $reference_hash{$reference} = 1;
	}

    }

}

foreach $j (sort keys %reference_hash) {
    print "$j\n";
}

#---------------------------------------------------------------
# Faculty names are below. Pipe-delimited record format is:
#   Field 1: last_name first_initial middle_initial (optional)
#   Field 2: start year (used to filter results, may be empty)
#   Field 3: end year (used to filter results, may be empty)
#---------------------------------------------------------------
__END__
biondich p|2000|
cullen theresa|2015|
dexter paul|1995|
dixon be|2000|
duke jd|2000|
finnell jt|2000|
friedlin j|2002|2012
gamache roland|1995|2012
grannis shaun|2000|
imler timothy|2004|
mamlin b|1995|
mcdonald clement|1974|2013
overhage jm|1980|2012
ragg S|2001|2007
rosenman mb|2000|2015
schadow g|2000|2010
schleyer titus|2013|
simonaitis linas|2004|2010
takesue blaine|2010|
thyvalikakath t|2013|
vreeman dj|2002|
were mc|2008|2015

#!/usr/bin/perl

use strict;

use YAML;
use Data::Dumper;


my $yamldir="/var/lib/puppet/enc/yaml";
my $nodename=$ARGV[0];


my $node=YAML::LoadFile("$yamldir/$nodename.yaml");


my $section;

my $manifest={ 	parameters 	=> {},
		classes		=> {},
	};

$manifest->{parameters}=$node->{attributes};
$manifest->{classes}=$node->{classes};

my $include=$node->{include};

my @searchorder=qw/	name 
			factory_role 
			factory_env
			factory_location
			default/;

#
# Build search suffix
#
my @searchlist;
foreach ( @searchorder) {
	my $searchsuffix;
	if ( /default/ ) {
		$searchsuffix='default';
	} else {
		$searchsuffix=$node->{attributes}->{$_};
	}

	push @searchlist, $searchsuffix if defined ( $searchsuffix );
}


foreach ( keys(%{$include} )) {
	my $included_file_content;
	next unless $include->{$_} eq 'true' ;
 	my $base_filename="$yamldir/include/$_.yaml";
	foreach ( @searchlist ) {
		my $fn=$base_filename . '.'. $_;
		printf("looking for %s\n",$fn);
		if ( -f $fn ) {
			$included_file_content=YAML::LoadFile($fn);
			last;
		}	
	}
	# print YAML::Dump($included_file_content);
	foreach $section ( qw/classes parameters environment/ ) {
		foreach ( keys(%{$included_file_content->{$section}}) ) {
			$manifest->{$section}->{$_}=$included_file_content->{$section}->{$_};
		}
	}
}

print YAML::Dump($manifest);
exit;

my $common=YAML::LoadFile("/var/lib/puppet/enc/yaml/common.yaml");

foreach $section ( qw/classes parameters environment/ ) {
	foreach	( keys(%{$common->{$section}}) ) {
		$manifest->{$section}->{$_}=$common->{$section}->{$_};		
	}
}


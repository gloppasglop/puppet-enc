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

sub load_include
{
	my $include=shift;
	foreach ( @{$include} ) {
		my $included_file_content;
 		my $base_filename="$yamldir/include/$_.yaml";
		foreach ( @searchlist ) {
			my $fn=$base_filename . '.'. $_;
			if ( -f $fn ) {
				printf("Found %s\n",$fn);
				$included_file_content=YAML::LoadFile($fn);
				last;
			}	
		}
		# print YAML::Dump($included_file_content);
		foreach $section ( qw/classes parameters environment include/ ) {
			if ( $section eq 'include') {
				load_include($included_file_content->{$section});
			} else {
				foreach ( keys(%{$included_file_content->{$section}}) ) {
					$manifest->{$section}->{$_}=$included_file_content->{$section}->{$_};
				}
			}
		}
		
	}
}


load_include($include);
print YAML::Dump($manifest);


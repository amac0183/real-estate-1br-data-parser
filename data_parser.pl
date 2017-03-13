#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use Scalar::Util qw(looks_like_number);
use JSON qw(to_json);

use constant START_INDEX => 5;
use constant END_INDEX => 87;

# Returns a hash containing city names as keys that contain the most recent rent values
sub most_recent_rent_by_city {
	my ($city_data) = @_;
	my %dataset;

	foreach my $key (keys %$city_data ) {
		my @rents = @{$city_data->{$key}};
		$dataset{$key} = $rents[@rents - 1];
	}

	return %dataset;
};

# Returns a hash containing city names as keys that contain an array of dates and rent values
sub monthly_rents_array_by_city {
	my ($cities_data, $dates) = @_;
	my %dataset;

	foreach my $key (keys %$cities_data ) {
		my %city_data;
		@{$city_data{"dates"}} = @{$dates};
		@{$city_data{"values"}} = @{$cities_data->{$key}};
		%{$dataset{$key}} = %city_data;
	}

	return %dataset;
};

my $csv_filename = 'City_MedianRentalPrice_1Bedroom.csv';
open(my $fh, '<:encoding(UTF-8)', $csv_filename)
  or die "Could not open file '$csv_filename' $!";

my @national_avg;
my @city_counts;
for ( my $i = 0; $i < END_INDEX - START_INDEX + 1; ++$i) {
	$national_avg[$i] = 0.00;
	$city_counts[$i] = 0;
}

my %data_by_city;
my @dates;
my $row = <$fh>;
chomp $row;

# Grab the dates
my @cells = split /,/, $row;
@dates = @cells[START_INDEX..END_INDEX];
for ( my $i = 0; $i < @dates; ++$i) {
	$dates[$i] =~ tr/"//d;
}

while ($row = <$fh>) {
	chomp $row;
	@cells = split /,/, $row;
	my $city_name = $cells[0];
	$city_name =~ tr/"//d;

	for ( my $i = START_INDEX; $i < END_INDEX + 1; ++$i) {
		my $index = $i - START_INDEX;
		if(!defined($cells[$i]) || !looks_like_number($cells[$i]) || $cells[$i] eq 0) {
			next;
		}

		my $value = sprintf '%.2f', $cells[$i];
		$cells[$i] = $value;

		$national_avg[$index] = $value + $national_avg[$index];
		++$city_counts[$i];
	}

	@{$data_by_city{$city_name}} = @cells[START_INDEX..END_INDEX];
}


for ( my $i = 0; $i < @national_avg; ++$i) {
	if($city_counts[$i] eq 0) {
		$national_avg[$i] = undef;
		next;
	}

	$national_avg[$i] = $national_avg[$i] / $city_counts[$i];
}


my %final_data_set;
my %most_recent_rent = most_recent_rent_by_city \%data_by_city;
%{$final_data_set{'mostRecentRentByCity'}} = %most_recent_rent;

my %rents_by_city = monthly_rents_array_by_city \%data_by_city, \@dates;
%{$final_data_set{'monthlyRentsByCity'}} = %rents_by_city;

my $jsonText = to_json \%final_data_set, { pretty => 1 };
my $json_filename = 'city_median_rental_price_1bedroom.json';
open(my $jsonfh, '>', $json_filename)
  or die "Could not open file '$json_filename' $!";
print $jsonfh $jsonText;
close $jsonfh;

print "Writing the json file done."






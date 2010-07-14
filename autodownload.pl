#! /usr/bin/perl
#
#   Patrick Dignan
#

use strict; 
use File::Path qw(make_path remove_tree);

# Array of supported protocols
my @supported_protos = { 'http' };

# Map supported protocols to methods
my %supported_proto_method = (
                http => \&get_http
            );

my ($source, $name, $version, $proto, $numargs, $file);
our @ARGV;

if ($#ARGV < 0) {
    die("Not enough arguments\n");
} elsif ($ARGV[0] !~ m/.*\.spec/i) {
    die("Not a valid file.  Must pass a .spec file\n");
} else {
    $file = $ARGV[0];
}

if (open(SPEC, $file) == 0) {
	print "Could not open file\n";
}

while(<SPEC>) {
    if ($_ =~ m/Source[^1-9]:/) {
        my @elements = split('[\s]+');
        $source = @elements[1];
        if ($source =~ m/^http:\/\//) {
            $proto = 'http';
        }
    } elsif ($_ =~ m/Name:/) {
        my @name_split = split('[\s]+');
        $name = @name_split[1];
    } elsif ($_  =~ m/Version:/) {
        my @ver_split = split('[\s]+');
        $version = @ver_split[1];
    }
}

if ($source ne '' && $name ne '' && $version ne '' && $proto ne '') {
    $source =~ s/%{name}/$name/;
    $source =~ s/%{version}/$version/;

    # top-level RPM build directory
    my $topdir = &get_topdir;

    if ( -d "${topdir}/SOURCES") {
        print "Changing to rpmbuild directory...\n";
        chdir ("${topdir}/SOURCES");
    } else {
        print "Creating SOURCES directory...\n";
        if (make_path("${topdir}/SOURCES") < 1) {
            die("Failed to create sources directory, check the permissions\n");
        }

        print "Changing to rpmbuild directory...\n";
        chdir ("${topdir}/SOURCES");
    }

    &{$supported_proto_method{$proto}}($source);
} else {
	print "bad values\n source: ${source} name: ${name} version: ${version} proto: ${proto}\n";
}

# Get sources with http as the protocol
# 
# Takes the source as an argument
sub get_http {
    my ($source) = @_;
    print "Getting source...\n";
    my $success = system('wget', $source);

    if ($success == 0) {
        print "Got source...\n";
    } else {
        print "Failed to get source!\n";
    }
}

# Get the topdir of the rpm build directory
sub get_topdir {
    my $result = `rpm --eval %{_topdir}`;
    $result =~ s/\n//g; # Remove any endlines
    return $result;
}

package DataAPIHotEntriesLite::EndPoint::HotEntries;
use strict;

use MT::DataAPI::Endpoint::Common;
use MT::DataAPI::Resource;
use MT::Stats;
use MT::DataAPI::Endpoint::Stats;

use constant LIMIT => 20;

sub get_hot_entries {
    my ($app, $endpoint) = @_;

    my ( $blog ) = context_objects(@_) or return;

    my $startDate = seven_days_ago();
    my $endDate   = today();

    my $provider = MT::Stats::readied_provider( $app, $blog ) or return;;
    $app->param('uniquePath', 1);
    my $data = $provider->pageviews_for_path(
        $app,
        {   startDate => $startDate,
            endDate   => $endDate,
        }
    );
    $data = MT::DataAPI::Endpoint::Stats::fill_in_archive_info( $data, $blog );

    my @ret_vals;
    my $i = 0;
    foreach my $entry ( @{$data->{items}} ) {
        next unless $entry->{archiveType} eq 'Individual';

        $i++;

        my $entry_id  = $entry->{entry}->{id};
        my $entry_obj = MT->model('entry')->load($entry_id);
        my $ret_val = { title     => $entry_obj->title(),
                        permalink => $entry_obj->permalink(),
                        ranking   => $i,
                      };
        push @ret_vals, $ret_val;

        last if $i == LIMIT;
    }

    return { startDate => $startDate,
             endDate   => $endDate,
             items     => \@ret_vals,
             limit     => ( $i < LIMIT ? $i : LIMIT ),
           };
}

sub today {
    my $time = time;
    return time_to_date( $time );
}

sub seven_days_ago {
    my $time = time - 7 * 24 * 60 * 60;
    return time_to_date( $time );
}

sub time_to_date {
    my ($time) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( $time );
    $year += 1900;
    $mon++;
    return sprintf( "%04d-%02d-%02d", $year, $mon, $mday );
}

1;

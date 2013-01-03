package GCMDemo::Web::Dispatcher;
use 5.10.0;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;
use Log::Minimal qw(infof warnf);

use WWW::Google::Cloud::Messaging;

my %reg_ids;

any '/' => sub {
    my ($c) = @_;
    return $c->render('index.tt');
};

any '/register' => sub {
    my ($c) = @_;

    $reg_ids{$c->req->param("regId")}++;

    return $c->create_response(200, [], ["OK\n"]);
};

any '/unregister' => sub {
    my ($c) = @_;

    %reg_ids = ();

    return $c->create_response(200, [], ["OK\n"]);
};

any '/send' => sub {
    my ($c) = @_;

    infof "send";

    state $api_key = "...";
    state $gcm = WWW::Google::Cloud::Messaging->new(api_key => $api_key);

     my $res = $gcm->send({
         registration_ids => [ keys %reg_ids ],
         collapse_key     => "update",
         data             => {
           message => 'blah blah blah',
         },
     });
    my $results = $res->results;
    while (my $result = $results->next) {
        my $reg_id = $result->target_reg_id;
        if ($result->is_success) {
            infof 'success: message_id: %s, reg_id: %s',
                $result->message_id, $reg_id;
        }
        else {
            warnf 'error: %s, reg_id: %s', $result->error, $reg_id;
        }

        if ($result->has_canonical_id) {
            infof 'refresh: reg_id %s is old! refreshed reg_id is %s',
                $reg_id, $result->registration_id;
        }
    }

    return $c->create_response(200, [], ["OK\n"]);
};

post '/account/logout' => sub {
    my ($c) = @_;
    $c->session->expire();
    return $c->redirect('/');
};

1;

#!/usr/bin/perl

# MIT license
use strict;
use warnings;
use URI::Escape;
use JSON::PP;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(hmac_sha1_base64);
use Time::HiRes qw(time);

use constant {
  CONSUMER_KEY => "Consumer key",
  SECRET_KEY   => "Consumer secret",
  OAUTH_TOKEN  => "Access token",
  SECRET_TOKEN => "Access token secret",
  TWITTER_API  => "https://api.twitter.com/1.1/statuses/",
};

# Access Twitter REST API with Oauth authentication
# @param string type of request
# @param string url to be appended to base url
# @param hash with HTTP request data
# @return string REST API response in JSON format
sub twitterOauth {
  my ($req, $url, %getData) = @_;
  my $secret_token = SECRET_TOKEN;
  my $secret_key = SECRET_KEY;
  my ($oauth_signature, $base_signature, $signing_key, $authorization, $response,
    $parameter) =  ('', '', '', '', '', '');
  my %oauth_parameters = (
    "oauth_consumer_key"     => CONSUMER_KEY,
    "oauth_nonce"            => md5_hex(int time() . int rand(~0)),
    "oauth_signature_method" => "HMAC-SHA1",
    "oauth_timestamp"        => int time(),
    "oauth_token"            => OAUTH_TOKEN,
    "oauth_version"          => "1.0",
    );

  $url = TWITTER_API . $url;
  %oauth_parameters = (%oauth_parameters, %getData);

  # Compute oauth_signature
  foreach $parameter (sort keys %oauth_parameters){
    $base_signature .= "$parameter=$oauth_parameters{$parameter}&"
  }
  chop($base_signature); #remove trailing & character

  $base_signature = uc($req) . '&' . uri_escape($url) . '&' . uri_escape($base_signature);
  $signing_key = uri_escape($secret_key) . '&' . uri_escape($secret_token);
  $oauth_signature = hmac_sha1_base64($base_signature, $signing_key);
  # Pad base64 output, CPAN Digest modules don't pad by convention
  while (length($oauth_signature) % 4) {
    $oauth_signature .= '=';
  }

  # Build authorization string for HTTP request
  $authorization = 'OAuth oauth_consumer_key="' . uri_escape($oauth_parameters{"oauth_consumer_key"}) .
    '", oauth_nonce="' . uri_escape($oauth_parameters{"oauth_nonce"}) .
    '", oauth_signature="' . uri_escape($oauth_signature) .
    '", oauth_signature_method="' . uri_escape($oauth_parameters{"oauth_signature_method"}) .
    '", oauth_timestamp="' . uri_escape($oauth_parameters{"oauth_timestamp"}) .
    '", oauth_token="' . uri_escape($oauth_parameters{"oauth_token"}) .
    '", oauth_version="' . uri_escape($oauth_parameters{"oauth_version"}) . '"';

  # Make HTTP request using curl
  $parameter = join('&', map{"$_=$getData{$_}"} keys %getData);
  $parameter = "--" . lc($req) . " \'$url\' --data \'$parameter\' --header \'Authorization: $authorization\'";
  $response = curl($parameter);

  return $response;
}

# Use curl to get webpage contents
# @param string with CLI arguments for curl
# @return string with webpage content
sub curl {
  my ($curl_args) = @_;
  my $response;

  # System call for curl
  $curl_args = 'curl -k --silent -A "' .
    'Mozilla/5.0 (Windows NT x.y; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0" ' .
    "$curl_args 2>&1";
  $response = qx{$curl_args};
  die "Unable to download webpage $curl_args " if ( $? == -1 );

  return $response;
}
# Example
print twitterOauth("GET", "user_timeline.json", (screen_name => "twitterdev", count => 12));

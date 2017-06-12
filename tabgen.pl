#!/usr/bin/perl

use strict;
use JSON;

#--- variables

my $infile = 'reddit-table.json';
my $wins_total = 0;
my $runes_total = 0;

#--- read from file

local $/;
open(my $fh, '<', $infile);
my $json   = <$fh>;
my $js = new JSON->relaxed(1);
my $data = $js->decode($json);

#--- link games to players

for my $g (@{$data->{'games'}}) {
  my $plr = $g->[0];
  if(!exists $data->{'players'}{$plr}) {
    die "Game for non-existent player $plr";
  }
  push(@{$data->{'players'}{$plr}{'games'}}, $g);
}

#--- output data

# table header
print "| Player | Reddit-id | Wins | # | Runes | Dump | Mode\n";
print "|:--|:--|:--|--:|--:|:--|:--:|\n";

# iterate over players (sorted by nick)
for my $plr (sort keys %{$data->{'players'}}) {
  my $p = $data->{'players'}{$plr};
  my ($wincnt, $runecnt) = (0,0);
  
  # player with link to player profile
  printf("|[%s](%s/%s.html)", $p->{'name'}, $data->{'profileurl'}, $plr);
  
  # reddit id
  print '|';
  printf('/u/%s', $p->{'redditid'}) if $p->{'redditid'}; # redditid
  
  # wins
  print "|";
  my $f;
  for my $g (@{$p->{'games'}}) {
    if($g->[3]) { # only won games
      print ' ' if $f;
      if($g->[4]) {
        printf("[%s](%s)", $g->[1], $g->[4]);
      } else {
        printf("%s", $g->[1]);
      }
      if($g->[2] > 3) {
        printf('(%d)', $g->[2]);
      }
      $wincnt++ if $g->[3];
    }
    $runecnt += $g->[2];
    $f = 1;
  }
  printf("|%s", ($wincnt > 0 ? $wincnt : '')); # win count
  printf("|%s", ($runecnt > 0 ? $runecnt : '')); # rune count
  
  #--- live game dump links (if they exist)
  
  if(exists $p->{'dump'}) {
    my $dump = $p->{'dump'}[0]; # currently supporting only one
    printf(
      "|[%s](%s)",
      $data->{'servers'}{$dump}{'short'},
      do {
        if($data->{'servers'}{$dump}{'dump'} =~ /=$/) {
          $data->{'servers'}{$dump}{'dump'} . $p->{'name'} . '.txt';
        } else {
          $data->{'servers'}{$dump}{'dump'} . '/' . $p->{'name'} . '/' .$p->{'name'} . '.txt';
        }
      }
    );
  } else {
    print '|';
  }
  
  #--- mode (tiles or console)
  
  if(exists $p->{'mode'}) {
    printf('|%s', $p->{'mode'});
  } else {
    print '|';
  }
  
  print "\n";
  $wins_total += $wincnt;
  $runes_total += $runecnt;
}

# totals

printf(
  "| **Total** |||%s|%s||\n", 
  ($wins_total > 0 ? $wins_total : ''),
  ($runes_total > 0 ? $runes_total : '')
);

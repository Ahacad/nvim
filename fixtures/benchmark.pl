#!/usr/bin/perl
use warnings;
use strict;

# which file to write the result
my $output_file = "./fixtures/benchmark.txt";

# where to get the neovim startup time data
my $sttime_file = "/tmp/nvim-startuptime";

# how to run the neovim
my $nvim_cmd = "nvim --headless --startuptime ".$sttime_file." -c 'au VimEnter * quitall'";

# get the last line of the result
sub read_last_line {
  return `tail -n1 /tmp/nvim-startuptime`;
}

# split and get the first number of the result
sub split_score {
  return split(' ', shift);
}

# run neovim with file if the first argument is not nil
sub run_nvim {
  if ($_[0]) {
    system($nvim_cmd." ".shift);
  } else {
    system($nvim_cmd);
  }
}

# run the test
sub run_test {
  # get the params
  my $n = shift;
  my $file = shift;

  # initialize records
  my @records = ();

  # test n times
  for (my $i = 0; $i < $n; $i++) {
    if ($file) {
      run_nvim($file);
    } else {
      run_nvim();
    }
    my @scores = split_score(read_last_line());
    my $score = $scores[0];
    push @records, $score;
  }

  # sort the array
  my @sorted_records = sort @records;

  # remove the smallest score
  shift @sorted_records;
  # remove the largest score
  pop @sorted_records;

  # calculate the average score
  my $sum = 0;
  foreach my $n (@sorted_records) {
    $sum = $sum + $n
  }
  my $avg = $sum / @sorted_records;


  # return the hashmap in the below structure
  # {
  #   "max": 0.00,
  #   "min": 0.00,
  #   "avg": 0.00
  # }
  return (max => $sorted_records[-1],
          min => $sorted_records[0],
          avg => $avg);
}

# write the result
sub write_result {
  # open the $output_file
  open(fh, ">", $output_file);

  # result format
  my $hint = << "EOF";
BENCHMARK (TEST 10 Times) (Unit: millisecond)
=============================================

==== Test 1, Open empty buffer ==============
Max elapse time: %.2f
Min elapse time: %.2f
Avg elapse time: %.2f

==== Test 2, Open markdown file =============
Max elapse time: %.2f
Min elapse time: %.2f
Avg elapse time: %.2f

==== Test 3, Open Lua code ==================
Max elapse time: %.2f
Min elapse time: %.2f
Avg elapse time: %.2f
EOF

  # get the input params
  my ($ia, $ib, $ic) = @_;

  # print the result to the file
  printf fh $hint,
    $ia->{max}, $ia->{min}, $ia->{avg},
    $ib->{max}, $ib->{min}, $ib->{avg},
    $ic->{max}, $ic->{min}, $ic->{avg};

  # close the file
  close(fh);
}

# run empty buffer test
my %buffer  = run_test(10);

# run markdown file test
my %md  = run_test(10, "README.md");

# run lua file test
my %lua  = run_test(10, "init.lua");

# and finally write the result
write_result(\%buffer, \%md, \%lua);
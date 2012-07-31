use Bio::SeqIO;
use Bio::Align::Utilities qw(cat);

require "subfuncs.pl";

# Bring in the file and format, or die with a nice
# usage statement if one or both arguments are missing.
my $usage  = "parse_fasta_to_genes.pl genbank_file fasta_file out_file\n";
my $gb_file   = shift or die $usage;
my $fa_file = shift or die $usage;
my $out_file = shift or die $usage;

my $whole_aln = make_aln_from_fasta_file ($fa_file);
my @gene_alns;

my $seqio_object = Bio::SeqIO->new(-file => $gb_file);
my $seq_object = $seqio_object->next_seq;

my $result_str = "";
while ($seq_object) {
	for my $feat_object ($seq_object->get_SeqFeatures) {
		if ($feat_object->primary_tag eq "CDS") {
			my $name = main_name_for_gb_feature($feat_object);
			my @locations = $feat_object->location->each_Location;
			my $cat_aln = 0;
			my $strand = 0;
			my $i = 0;
			foreach $loc (@locations) {
				$name .= "_$i";
				$strand = $loc->strand;
				my $start = $loc->start;
				my $end = $loc->end;
				my $curr_slice = $whole_aln->slice($start, $end);
				if ($cat_aln == 0) {
					$cat_aln = $curr_slice;
				} else {
					$cat_aln = cat($cat_aln, $curr_slice);
				}
				if ($result_str eq "") { $result_str = "$name\t$start"; }
				$cat_aln->description($name);
				push @gene_alns, $cat_aln;
				$result_str = "";
			}
		}
	}
	$seq_object = $seqio_object->next_seq;
}

	open my $gene_file, ">$out_file.fasta";
	truncate $gene_file, 0;

foreach my $aln (@gene_alns) {
	my $gene_name = $aln->description();
	foreach my $seq ($aln->each_seq()) {
		my $name = $gene_name . "_" . $seq->length();
		print $gene_file ">$name\n";
		print $gene_file $seq->seq() . "\n";
	}
}
	close $gene_file;

package Dist::Zilla::PluginBundle::CHGOVUK;
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy',
     'Dist::Zilla::Role::PluginBundle::Config::Slicer';
 
use namespace::autoclean;
 
has installer => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { $_[0]->payload->{installer} || 'MakeMaker' },
);
 
sub build_file {
    my $self = shift;
    $self->installer =~ /MakeMaker/ ? 'Makefile.PL' : 'Build.PL';
}
 
sub configure {
    my $self = shift;
 
    my @accepts = qw( MakeMaker MakeMaker::IncShareDir ModuleBuild ModuleBuildTiny );
    my %accepts = map { $_ => 1 } @accepts;
 
    unless ($accepts{$self->installer}) {
        die sprintf("Unknown installer: '%s'. " .
                    "Acceptable values are MakeMaker, ModuleBuild and ModuleBuildTiny\n",
                    $self->installer);
    }
 
    my @dirty_files = ('dist.ini', 'Changes', 'META.json', 'README.md', $self->build_file);
    my @exclude_release = ('README.md');
 
    $self->add_plugins(
        [ 'NameFromDirectory' ],
 
        # Make the git repo installable
        [ 'Git::GatherDir', { exclude_filename => [ $self->build_file, 'META.json', 'LICENSE', @exclude_release ] } ],
        #[ 'CopyFilesFromBuild', { copy => [ 'META.json', 'LICENSE', $self->build_file ] } ],
 
        # should be after GatherDir
        [ 'Git::NextVersion', { first_version => '0.01', version_regexp => '^(.+)$' } ],
 
        [ 'ReversionOnRelease', { prompt => 1 } ],
 
        # after ReversionOnRelease for munge_files, before Git::Commit for after_release
        [ 'NextRelease', { format => '%-v  %{yyyy-MM-dd}d' } ],
 
        [ 'Git::Check', { allow_dirty => \@dirty_files } ],
 
        # Make Github center and front
        [ 'GithubMeta', { issues => 1 } ],
        [ 'ReadmeAnyFromPod', { type => 'markdown', filename => 'README.md', location => 'root' } ],
 
        # Set no_index to sensible directories
        [ 'MetaNoIndex', { directory => [ qw( t xt inc share eg examples ) ] } ],
 
        [ 'AutoPrereqs' ],
        [ $self->installer ],
        [ 'MetaJSON' ],
 
        # standard stuff
        [ 'PodSyntaxTests' ],
        [ 'MetaYAML' ],
        [ 'License' ],
        [ 'ReadmeFromPod' ],
        [ 'ExtraTests' ],
        [ 'ExecDir', { dir => 'script' } ],
        [ 'ShareDir' ],
        [ 'Manifest' ],
        [ 'ManifestSkip' ],
 
        [ 'CheckChangesHasContent' ],
        [ 'TestRelease' ],
        [ 'ConfirmRelease' ],
        [ 'FakeRelease' ],
 
        [ 'CopyFilesFromRelease', { match => '\.pm$' } ],
        [ 'Git::Commit', {
            commit_msg => '%v',
            allow_dirty => \@dirty_files,
            allow_dirty_match => '\.pm$', # .pm files copied back from Release
        } ],
        [ 'Git::Tag', { tag_format => '%v', tag_message => '' } ],
        [ 'Git::Push', { remotes_must_exist => 0 } ],
 
    );
}
 
__PACKAGE__->meta->make_immutable;
1;
 
__END__
 
=head1 NAME
 
Dist::Zilla::PluginBundle::CHGOVUK - Dist::Zilla plugin defaults for Companies House
 
=head1 SYNOPSIS
 
  ; dist.ini
  name = Dist-Name
  [@CHGOVUK]
  installer = ModuleBuildTiny
 
=head1 DESCRIPTION
 
This is a Dist::Zilla plugin bundle that implements the opinionated build
process of Companies House. Roughly equivalent to:
 
  # TBD
 
=head1 SEE ALSO
 
L<Dist::Milla>
 
=cut
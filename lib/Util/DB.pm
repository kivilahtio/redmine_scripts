package Util::DB;

use Function::Parameters;

sub new {
    my ($self, $params) = @_;

    my $dsn = "DBI:mysql:database=redmine;host=localhost;port=3306";
    my $dbh = DBI->connect($dsn);
    #my $dbh = DBI->connect($dsn, 'redmineuser', 'redminepass');
    return $dbh;
}

fun getTimeEntries($user_id) {
    my $dbh = __PACKAGE__->new();
    my $sth = $dbh->prepare("SELECT spent_on, created_on, hours FROM time_entries WHERE user_id = ? ORDER BY spent_on DESC, created_on DESC");
    $sth->execute($user_id);
    my $timeEntries = $sth->fetchall_arrayref({});
    return $timeEntries;
}

1;

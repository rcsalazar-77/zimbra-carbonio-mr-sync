#!/usr/bin/perl -w

# =====================================================================
#  Zimbra Carbonio MR Sync - Remote Script
#  Created by: Roberto Salazar (rcsalazar77@gmail.com)
#  License: Public Domain
#
#  This script is provided as-is for public use.
#  Feel free to modify and distribute as needed.
# =====================================================================

use strict;
use warnings;
use POSIX ();
use File::Spec;

# Cargar configuración
my $config_file = File::Spec->catfile(File::Spec->updir(), 'config', 'config.pl');
require $config_file or die "No se pudo cargar configuración: $@";

my $dir = $CONFIG{'local_dir'};
chdir($dir) or die "No se pudo cambiar al directorio $dir: $!";

my $email = $ARGV[0];

&daemonize();

##--------------------
## Programa Principal
##--------------------
&read_logs("INICIO: Programa principal");

if ($email) {
    my $file = "/tmp/$email.tgz";

    if (!-e $file) {
        &read_logs("ERROR: No existe archivo de backup remoto para $email: $file");
        &read_logs("FIN: Programa principal");
        exit(0);
    }

    my $size = -s $file;
    if (!defined $size || $size == 0) {
        &read_logs("ERROR: Archivo remoto vacio para $email: $file");
        unlink $file if -e $file;
        &read_logs("FIN: Programa principal");
        exit(0);
    }

    &read_logs("TAREA: Restaurando buzon: $email. Tamano TGZ=$size bytes");

    my $restore_cmd  = "$CONFIG{'zmmailbox_bin'} -z -m '$email' -t $CONFIG{'restore_timeout'} postRestURL '//?fmt=tgz&resolve=$CONFIG{'restore_resolve'}' '$file' >>'$dir/LOGS/remote_restore_stdout.log' 2>>'$dir/LOGS/remote_restore_errors.log'";
    my $rc_restore   = system("/bin/bash", "-c", $restore_cmd);
    my $exit_restore = $rc_restore >> 8;

    if ($exit_restore != 0) {
        &read_logs("ERROR: Fallo restauracion para $email. Exit=$exit_restore");
    } else {
        &read_logs("OK: Restauracion finalizada para $email. Exit=$exit_restore");
    }

    &read_logs("TAREA: Eliminando backup remoto : $file");
    unlink $file if -e $file;
}

&read_logs("FIN: Programa principal");

## Subrutina en modo daemon
sub daemonize {
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    exit(0) if $pid;

    POSIX::setsid() or die "setsid: $!";

    chdir("/") or die "chdir /: $!";
    umask 0;

    open(STDIN,  "</dev/null");
    open(STDOUT, ">>$dir/LOGS/remote_daemon_stdout.log");
    open(STDERR, ">>$dir/LOGS/remote_daemon_stderr.log");

    select(STDOUT); $| = 1;
    select(STDERR); $| = 1;
}

## Subrutina de impresion y logs
sub read_logs {
    my ($msg) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
    $year = 1900 + $year;
    $mon  = 1 + $mon;

    $mon  = "0".$mon  if ($mon  < 10);
    $mday = "0".$mday if ($mday < 10);
    $hour = "0".$hour if ($hour < 10);
    $min  = "0".$min  if ($min  < 10);
    $sec  = "0".$sec  if ($sec  < 10);

    my $now = "$year-$mon-$mday";
    my $log_prefix = $CONFIG{'log_prefix'};
    my $log_dir = File::Spec->catdir($dir, $CONFIG{'log_dir'});
    my $file_log = File::Spec->catfile($log_dir, "$log_prefix$now");

    open(my $LOG, ">>", $file_log) or return;
    print $LOG "$year-$mon-$mday $hour:$min:$sec : $msg\n";
    print STDOUT "$year-$mon-$mday $hour:$min:$sec : $msg\n";
    close($LOG);
}
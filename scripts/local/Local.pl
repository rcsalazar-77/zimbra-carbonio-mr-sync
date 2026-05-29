#!/usr/bin/perl -w

# =====================================================================
#  Zimbra Carbonio MR Sync - Local Script
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
my $buzones_file = File::Spec->catfile($dir, $CONFIG{'buzones_file'});
chdir($dir) or die "No se pudo cambiar al directorio $dir: $!";

&daemonize();

# Construir comandos SSH con configuración
my $ssh_cmd = "/usr/bin/ssh -i '$CONFIG{'ssh_key_file'}' -p $CONFIG{'ssh_port'} -o StrictHostKeyChecking=no $CONFIG{'ssh_user'}\@$CONFIG{'ssh_host'}";
my $scp_cmd = "/usr/bin/scp -i '$CONFIG{'ssh_key_file'}' -P $CONFIG{'ssh_port'} -o StrictHostKeyChecking=no";

##--------------------
## Programa Principal
##--------------------
&read_logs("INICIO: Programa principal");

open(my $USERS, '<', $buzones_file) or die "No se pudo abrir $buzones_file: $!";

my $i = 1;
while (my $email = <$USERS>) {
    chomp($email);
    next if !$email;
    next if $email =~ /^\s*$/;

    my $file_tmp = "/tmp/$email.tgz.tmp";
    my $file_ok  = "/tmp/$email.tgz";

    &read_logs("TAREA: Creando backup de buzon: [$i] - $email");

    unlink $file_tmp if -e $file_tmp;
    unlink $file_ok  if -e $file_ok;

    # ---------------------------------------------------------
    # TIPOS DE BACKUP DISPONIBLES
    # ---------------------------------------------------------

    # BACKUP INCREMENTAL (por rango de fechas)
    # Descomentar cuando se requiera migracion incremental
    # 'backup_query' => '//?fmt=tgz&query=after:02/20/2024 before:02/26/2024',

    # BACKUP FULL (todo el buzon) - POR DEFECTO
    my $backup_cmd = "$CONFIG{'zmmailbox_bin'} -z -m '$email' -t $CONFIG{'backup_timeout'} getRestURL '$CONFIG{'backup_query'}' > '$file_tmp' 2>>'$dir/LOGS/getrest_errors.log'";

    # ---------------------------------------------------------

    my $rc_backup   = system("/bin/bash", "-c", $backup_cmd);
    my $exit_backup = $rc_backup >> 8;

    if (!-e $file_tmp) {
        &read_logs("ERROR: No se genero archivo temporal para $email. Exit=$exit_backup");
        $i++;
        sleep($CONFIG{'delay_between_tasks'});
        next;
    }

    my $size_local = -s $file_tmp;
    if (!defined $size_local || $size_local == 0) {
        &read_logs("ERROR: Backup vacio para $email. Exit=$exit_backup. Se descarta.");
        unlink $file_tmp;
        $i++;
        sleep($CONFIG{'delay_between_tasks'});
        next;
    }

    if (!rename($file_tmp, $file_ok)) {
        &read_logs("ERROR: No se pudo renombrar $file_tmp a $file_ok para $email: $!");
        unlink $file_tmp if -e $file_tmp;
        $i++;
        sleep($CONFIG{'delay_between_tasks'});
        next;
    }

    &read_logs("OK: Backup generado para $email. Tamano local=$size_local bytes. Exit=$exit_backup");

    &read_logs("TAREA: Transfiriendo backup a nuevo servidor: [$i] - $email");
    my $rc_scp   = system("$scp_cmd '$file_ok' $CONFIG{'ssh_user'}\@$CONFIG{'ssh_host'}:'/tmp/' >>'$dir/LOGS/scp_stdout.log' 2>>'$dir/LOGS/scp_errors.log'");
    my $exit_scp = $rc_scp >> 8;

    if ($exit_scp != 0) {
        &read_logs("ERROR: Fallo SCP para $email. Exit=$exit_scp");
        &read_logs("TAREA: Eliminando backup local por fallo SCP : $file_ok");
        unlink $file_ok if -e $file_ok;
        $i++;
        sleep($CONFIG{'delay_between_tasks'});
        next;
    }

    my $size_remote = `$ssh_cmd "stat -c%s '/tmp/$email.tgz' 2>/dev/null"`;
    chomp($size_remote);
    $size_remote =~ s/^\s+|\s+$//g;

    if (!$size_remote || $size_remote !~ /^\d+$/) {
        &read_logs("ERROR: No se pudo validar tamano remoto para $email");
        &read_logs("TAREA: Eliminando backup local : $file_ok");
        unlink $file_ok if -e $file_ok;
        $i++;
        sleep($CONFIG{'delay_between_tasks'});
        next;
    }

    if ($size_remote != $size_local) {
        &read_logs("ERROR: Tamano distinto tras SCP para $email. Local=$size_local Remote=$size_remote");
        &read_logs("TAREA: Eliminando backup local : $file_ok");
        unlink $file_ok if -e $file_ok;
        $i++;
        sleep($CONFIG{'delay_between_tasks'});
        next;
    }

    &read_logs("OK: Transferencia SCP validada para $email. Local=$size_local Remote=$size_remote");

    &read_logs("TAREA: Eliminando backup local : $file_ok");
    unlink $file_ok if -e $file_ok;

    while (1) {
        my $running = `$ssh_cmd "ps -ef | grep '[z]mmailbox .*postRestURL' | wc -l"`;
        chomp($running);
        $running =~ s/^\s+|\s+$//g;
        $running = 0 if !$running || $running !~ /^\d+$/;

        if ($running < $CONFIG{'max_remote_restore'}) {
            &read_logs("INFO: Restauraciones remotas activas=$running. Hay cupo para $email");
            last;
        }

        &read_logs("INFO: Restauraciones remotas activas=$running. Esperando cupo para $email...");
        sleep 5;
    }

    &read_logs("TAREA: Restaurando backup en servidor remoto: [$i] - $email");
    my $rc_remote   = system("$ssh_cmd \"/usr/bin/perl $dir/Remote.pl '$email'\" >>'$dir/LOGS/remote_launch_stdout.log' 2>>'$dir/LOGS/remote_launch_errors.log'");
    my $exit_remote = $rc_remote >> 8;

    if ($exit_remote != 0) {
        &read_logs("ERROR: Fallo al invocar Remote.pl para $email. Exit=$exit_remote");
    } else {
        &read_logs("OK: Remote.pl invocado correctamente para $email");
    }

    $i++;
    sleep 1;
}

close($USERS);
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
    open(STDOUT, ">>$dir/LOGS/local_daemon_stdout.log");
    open(STDERR, ">>$dir/LOGS/local_daemon_stderr.log");

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
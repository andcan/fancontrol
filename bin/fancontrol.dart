import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main () {
  Map<String, int> conf = JSON.decoder.convert(new File('/etc/conf.d/dart/fancontrol/fancontrol.json').readAsStringSync());
  Map<String, int> fans = <String, int>{};
  Map<String, int> lastdelta = <String, int> {};
  RegExp regex = new RegExp(r'GPU\s*\d\d\d\d:(\d\d):\d\d\.\d\s*Temperature\s*GPU\s*Current\s*Temp\s*:\s*(\d\d)\s*C', multiLine: true, caseSensitive: true);
  new Timer.periodic(new Duration(seconds: 2), (timer) {
    Process.run('nvidia-smi', <String>['-q', '-d', 'TEMPERATURE']).then((result) {
      if (result.stdout is String) {
        regex.allMatches(result.stdout).forEach((match) {
          String id = match[1];
          id = (int.parse(id) - 1).toString();
          int speed, temp = int.parse(match[2]), targettemp = conf[id],
            delta = temp - targettemp, increment = delta - (lastdelta[id] == null ? 0 : lastdelta[id]);
            lastdelta[id] = delta;
          if (fans.containsKey(id)) {
            speed = fans[id];
          } else {
            fans[id] = speed = 50;
          }
          if (delta > -5 && delta <= 0 ) {
            speed += (increment < 0) ? 2 * increment :  4 * increment; 
          }
          speed += delta;          
          if (speed > 100) {
            speed = 100;
          } else if (speed < 30) {
            speed = 30;
          }
          fans[id] = speed;
          Process.run('nvidia-settings', <String>['-a',
                                                  '[gpu:$id]/GPUFanControlState=1',
                                                  '-a',
                                                  '[fan:$id]/GPUCurrentFanSpeed=$speed'
                                                  ]).then((result) {
            print ('[gpu:$id] Temp $temp°(${increment > 0 ? '+$increment' : '$increment'}°) Fan $speed%${result.stderr == '' ? '' : 'err! ${result.stderr}' }');
          });
        });
      }
    });
  });
}

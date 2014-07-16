import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main () {
  Map<String, int> conf = JSON.decoder.convert(new File('conf.d/fancontrol.json').readAsStringSync());
  Map<String, int> fans = <String, int>{};
  RegExp regex = new RegExp(r'GPU\s*\d\d\d\d:(\d\d):\d\d\.\d\s*Temperature\s*GPU\s*Current\s*Temp\s*:\s*(\d\d)\s*C', multiLine: true, caseSensitive: true);
  new Timer.periodic(new Duration(seconds: 2), (timer) {
    Process.run('nvidia-smi', <String>['-q', '-d', 'TEMPERATURE']).then((result) {
      if (result.stdout is String) {
        regex.allMatches(result.stdout).forEach((match) {
          String id = match[1];
          id = (int.parse(id) - 1).toString();
          int speed, temp = int.parse(match[2]), targettemp = conf[id];
          if (fans.containsKey(id)) {
            speed = fans[id];
          } else {
            fans[id] = speed = 50;
          }          
          speed += (temp - targettemp);
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
            print ('[gpu:$id] Temp $temp° Fan $speed% err: ${result.stderr}');
          });
        });
      }
    });
  });
}

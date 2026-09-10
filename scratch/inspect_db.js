const { Client } = require('ssh2');
const conn = new Client();
conn.on('ready', () => {
  const cmd = `
    mysql -u u170253497_healthexpress -p'HealthExpress@2026' u170253497_healthexpress -e "
      SHOW TABLES;
      DESCRIBE appointments;
      DESCRIBE doctor_hospitals;
    "
  `;
  conn.exec(cmd, (err, stream) => {
    if (err) throw err;
    let stdout = '';
    let stderr = '';
    stream.on('data', d => stdout += d);
    stream.stderr.on('data', d => stderr += d);
    stream.on('close', () => {
      console.log('STDOUT:\n' + stdout);
      if (stderr) console.log('STDERR:\n' + stderr);
      conn.end();
    });
  });
}).connect({
  host: '147.93.101.73',
  port: 65002,
  username: 'u170253497',
  password: 'Showsnap@987'
});

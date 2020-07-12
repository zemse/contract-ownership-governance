import ganache from 'ganache-core';

export const startGanacheServer = () => {
  global.server = ganache.server({
    gasPrice: '0',
  });
  global.server.listen(7545, () => {
    console.log('\x1b[2m%s\x1b[0m', '      Ganache Started on 7545..');
  });
};

// Stimulus controller for the configurator
// Uses global Stimulus object loaded from CDN

(() => {
  const application = window.Stimulus || Stimulus.Application.start();

  application.register('configurator', class extends Stimulus.Controller {
    static targets = []; // add targets if needed

    next(event) {
      // This controller may not be used if the configurator relies on Turbo Streams,
      // but we keep it as placeholder for future interactions.
    }
  });
})();

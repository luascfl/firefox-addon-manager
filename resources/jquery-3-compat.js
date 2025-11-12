(function ($) {
  if (!$ || !$.fn) {
    return;
  }

  // Re-introduce deprecated event shorthands for libraries expecting them
  var eventAliases = {
    load: 'load',
    unload: 'unload',
    error: 'error'
  };

  Object.keys(eventAliases).forEach(function (name) {
    var original = $.fn[name];
    $.fn[name] = function (arg) {
      if (typeof arg === 'function') {
        return this.on(eventAliases[name], arg);
      }
      if (original) {
        return original.apply(this, arguments);
      }
      return this.trigger(eventAliases[name]);
    };
  });

  if (!$.fn.size) {
    $.fn.size = function () {
      return this.length;
    };
  }
})(window.jQuery);

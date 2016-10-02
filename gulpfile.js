'use strict';

var gulp = require('gulp');
// Fonts
gulp.task('fonts', function() {
    gulp.src(
        'node_modules/bootstrap/fonts/*'
    ).pipe(gulp.dest('public/src/fonts/'));
});

var gulp = require('gulp');
var runSequence = require('run-sequence');

var concat = require('gulp-concat');
var coffee = require('gulp-coffee');
var sass = require('gulp-sass');
var uglify = require('gulp-uglify');
var ngTemplates = require('gulp-ng-templates');


// PUBLIC INTERFACE ========================================================================

gulp.task('public_styles', function() {
  gulp.src('./public/sass/main.sass')
    .pipe(sass().on('error', sass.logError))
    .pipe(gulp.dest('./public/built/'));
});

gulp.task('public_templates', function () {
	return gulp.src(['./public/templates/*.html', './public/templates/**/*.html'])
		.pipe(ngTemplates({
			filename: 'templates.js',
			module: 'RAFrontendTemplates',
			path: function (path, base) {
				return "/templates/" + path.replace(base, '');
			}
		}))
		.pipe(gulp.dest('./public/built/'));
});

gulp.task('public_app', function() {
  gulp.src([
    './public/coffee/engine.coffee',
    './public/coffee/api.coffee',
    './public/coffee/socket.coffee',
    './public/directives/**/*.coffee',
    './public/ext/angular-relative-date.coffee',
    './public/coffee/controllers/*.coffee',
    './public/coffee/controllers/**/*.coffee',
    './public/coffee/app.coffee',
  ])
    .pipe(concat('engine.coffee'))
    .pipe(coffee({bare: true}))
    .pipe(gulp.dest('./public/built/'));
});

gulp.task('public_minjs', function() {
  gulp.src([
    './public/built/templates.js',
    './public/built/engine.js'
  ])
    .pipe(concat('app.min.js'))
    .pipe(uglify())
    .pipe(gulp.dest('./public/built/'));
});

gulp.task('public_script', function(){
  runSequence(['public_templates', 'public_app'], 'public_minjs');
});

gulp.task('public', function(){
  gulp.run('public_styles');
  gulp.run('public_script');
});


// ADMIN INTERFACE ========================================================================

gulp.task('admin_styles', function() {
  gulp.src('./admin/sass/main.sass')
    .pipe(sass().on('error', sass.logError))
    .pipe(gulp.dest('./admin/built/'));
});

gulp.task('admin_templates', function () {
	return gulp.src([
    './admin/templates/*.html',
    './admin/templates/**/*.html',
    './admin/directives/**/*.html'
  ])
		.pipe(ngTemplates({
			filename: 'templates.js',
			module: 'RAAdminTemplates',
			path: function (path, base) {
				return "/admin/templates/" + path.replace(base, '');
			}
		}))
		.pipe(gulp.dest('./admin/built/'));
});

gulp.task('admin_app', function() {
  gulp.src([
    './admin/coffee/engine.coffee',
    './admin/coffee/api.coffee',
    './admin/coffee/socket.coffee',
    './admin/directives/**/*.coffee',
    './admin/coffee/controllers/*.coffee',
    './admin/coffee/app.coffee'
  ])
    .pipe(concat('engine.coffee'))
    .pipe(coffee({bare: true}))
    .pipe(gulp.dest('./admin/built/'));
});

gulp.task('admin_minjs', function() {
  gulp.src([
    './admin/built/templates.js',
    './admin/built/engine.js'
  ])
    .pipe(concat('app.min.js'))
    .pipe(uglify())
    .pipe(gulp.dest('./admin/built/'));
});

gulp.task('admin_script', function(){
  runSequence(['admin_templates', 'admin_app'], 'admin_minjs');
});

gulp.task('admin', function(){
  gulp.run('admin_styles');
  gulp.run('admin_script');
});



// EXECUTION ===============================================================================

gulp.task('watch', function() {
  gulp.watch('./public/**/*.coffee', ['public_script']);
  gulp.watch('./public/**/*.sass', ['public_styles']);
  gulp.watch('./public/**/*.html', ['public_script']);

  gulp.watch('./admin/**/*.coffee', ['admin_script']);
  gulp.watch('./admin/**/*.sass', ['admin_styles']);
  gulp.watch('./admin/**/*.html', ['admin_script']);
});

gulp.task('default', function(){
  gulp.run('public');
  gulp.run('admin');
});

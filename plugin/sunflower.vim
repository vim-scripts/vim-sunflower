"==============================================================================
" File: sunflower.vim
" Description: Adjust colorscheme depending on whether it is night or day.
" Maintainer: Göktuğ Kayaalp <self@gkayaalp.com>
" Version: 0.1.1
" License: BSD2 <../LICENSE>
"==============================================================================

" Section: Initialisation of Variables {{{
if !has('python') || !has('autocmd')
    finish
endif

if !exists('g:sunflower_lat')
    let g:sunflower_lat=0
endif

if !exists('g:sunflower_long')
    let g:sunflower_long=0
endif

if !exists('g:sunflower_colorscheme_night')
    let g:sunflower_colorscheme_night='default'
endif

if !exists('g:sunflower_colorscheme_day')
    let g:sunflower_colorscheme_day='default'
endif

if !exists('g:sunflower_set_background')
    let g:sunflower_set_background=1
endif

if !exists('g:sunflower_install_autocommand')
    let g:sunflower_install_autocommand=1
endif

let g:__sunflower_initialised=0

" }}}

" Section: Plugin Code {{{

" Function: __SunflowerInit()
" Runs initialisation code for the Python part of Sunflower. Defines the
" Helianthus class, and assigns an instance of it to Sunflower.
function! __SunflowerInit()
python <<EOF
import vim
import ephem
from datetime import datetime

class Helianthus(object):
    def __init__(self):
        self.rising_today = None
        self.setting_today = None

        self.today = datetime.today()
        self.now = datetime.now()
        self.observer = ephem.Observer()

        self.observer.lat   = str(vim.vars['sunflower_lat'])
        self.observer.long  = str(vim.vars['sunflower_lat'])
        self.set_background = bool(vim.vars['sunflower_set_background'])

        self.__update()

    def _update(self):
        'Update variables with new values.'
        # The user might have changed these in the session, so update them.
        self.observer.lat   = str(vim.vars['sunflower_lat'])
        self.observer.long  = str(vim.vars['sunflower_lat'])
        self.set_background = bool(vim.vars['sunflower_set_background'])

        # Do not be eager to compute the position of the Sun every call.
        self.now = datetime.today()
        if self.now.day != self.today.day:
            self.__update()

    def __update(self):
        next_rise     = ephem.localtime(self.observer.next_rising(ephem.Sun()))
        next_set      = ephem.localtime(self.observer.next_setting(ephem.Sun()))
        previous_rise = ephem.localtime(self.observer.previous_rising(ephem.Sun()))
        previous_set  = ephem.localtime(self.observer.previous_setting(ephem.Sun()))

        # If the next rising of sun is past today, we have already seen a sunrise
        # today; otherwise we are yet to do so.
        self.rising_today = previous_rise if next_rise > self.today else next_rise
        self.setting_today = next_set if next_set.day == self.today.day else previous_set

    def day(self):
        return self.rising_today < self.now < self.setting_today

    def change(self):
        self._update()
        if self.day():
            vim.command('colorscheme %s' % vim.vars['sunflower_colorscheme_day'])
            if self.set_background:
                vim.command('set background=light')
        else:
            vim.command('colorscheme %s' % vim.vars['sunflower_colorscheme_night'])
            if self.set_background:
                vim.command('set background=dark')

Sunflower = Helianthus()
EOF
endfunction
" }}}

" Section: The code for changing the theme {{{
function! __SunflowerFindTheSun()
    python Sunflower.change()
endfunction

function! SunflowerFindTheSun()
    if g:__sunflower_initialised != 1
        call __SunflowerInit()
        let g:__sunflower_initialised=1
    endif
    call __SunflowerFindTheSun()
endfunction

" }}}

" Section: Postamble {{{

autocmd VimEnter * call SunflowerFindTheSun()
if g:sunflower_install_autocommand
    autocmd BufWritePost * call SunflowerFindTheSun()
endif

" }}}


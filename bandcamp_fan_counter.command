#!/usr/bin/env conda run -n base python

# requirs among others PySimpleGUI, validators, pandas, BeautifulSoup; probably best to run through conda

from count_fans_bc import bc_counter
import PySimpleGUI as sg
import webbrowser
import pathlib

stars = '*'*16
start_string = f'!!! {stars} Wellcome to BANDCAMP HELPER  ((( beta ))) {stars} !!!'
explainer = """ Input a track/album to collect and output fans that have bought more than two of them. 
After that, go and explore their library and maybe buy some more good tracks!"""

sg.theme('DarkGrey11')
sg.set_options(font=("Marker Felt Wide", 16))

right_click_menu = ['Used', ['Copy', 'Exit']]
layout =  [[sg.Text(start_string)]]
layout += [[sg.Text('Tracks to be counted', justification='c')]]  
layout += [[sg.Text(f'{i}. '), sg.CBox('', key=f'-CB{i}-'), sg.Input(k=f'-IN{i}-')] for i in range(1, 10)] 
layout += [[sg.Button('Start selected',) ,sg.Button('Start all', bind_return_key=True)]]
layout += [[sg.Button('Clear input'), sg.Button('Undo clear input')]]
layout += [[sg.Output(size=(60,10), key= '_output_')]]
layout += [[sg.Button('Clear log')]]

window = sg.Window(start_string, layout, right_click_menu=right_click_menu, 
    grab_anywhere=True,resizable=True,finalize=True, element_justification='c')

def show_table(data, header_list, fn):
    data_frame = data.copy()
    data = data.values.tolist()
    layout = [
        [sg.Table(values=data,
                  headings=header_list,
                  font='Helvetica', max_col_width=65, justification='left',
                  num_rows=12, key='_linksstable_', enable_events=True, pad=(25,25),
                  display_row_numbers=True,auto_size_columns=True,)],
        [sg.Button('Save to csv'), sg.Button('Close')]]
    window = sg.Window(fn, layout, grab_anywhere=True, element_justification='c')

    # keep table open as new event
    while True:
        event, values = window.read()
        if event in (sg.WINDOW_CLOSED, None, 'Close'):
            break
        if event == '_linksstable_':
            url = data[ values['_linksstable_'][0] ][0]
            webbrowser.open(url)
        elif event == 'Save to csv':
            desktop = pathlib.Path.home() / 'Desktop'
            sg.Popup('saving data to:', desktop)
            try:
                print(desktop)
                data_frame.to_csv( desktop / 'fans_bc.csv')
            except Exception as e:
                print(e)

    window.close()



def analyze_n_display(track_list):
    track_list = list(filter(None, track_list))
    fn = 'Final grouped results'
    data = bc_counter(track_list)
    show_table(data, list(data.columns), fn)
    return data

def output():
    try:
        data = analyze_n_display(track_list)
        return data
    except Exception as e:
        if type(e).__name__ =='AttributeError':
            pass
        else: 
            print(e)

# this print puts default text in sg.Output 
print(start_string, '\n Press Enter to Start All')

# main event 
while True:
    event, values = window.read()
    if event in (sg.WINDOW_CLOSED, 'Exit'):
        break
    elif event == 'About...':
        window.disappear()
        sg.popup('About this program:', 
            """In my opinion people are still best for music recommendations. 
            How do you find the ones who match with you though \n?""", explainer, grab_anywhere=True)
        window.reappear()

    elif event == 'Start selected':
        check_box = list(values.values())[::2]
        links = list(values.values())[1::2]
        values_dict = dict(zip(links, check_box))
        track_list = [elem for elem in values_dict if values_dict[elem] == True]
        output()

    elif event == 'Start all':
        track_list = list(values.values())[1::2]
        output()

    elif event == 'Clear input':
        history = {}
        for i in range(0,9):
            history[f'-IN{i}-'] = list(values.values())[1::2][i]
            history[f'-CB{i}-'] = list(values.values())[::2][i]
        for i in range(1,10):
            window[f'-IN{i}-'].Update('')
            window[f'-CB{i}-'].Update(value=False)
    elif event == 'Undo clear input':
        try:
            for i in range(1,10):
                window[f'-IN{i}-'].Update(history[f'-IN{i-1}-'])
                window[f'-CB{i}-'].Update(value=history[f'-CB{i-1}-'])
        except Exception as e:
            if e.args[0] == "name 'history' is not defined":
                print('heh, nothing was cleared yet, nothing to bring back')
            else:
                print(e)

    elif event == 'Clear log':
        window['_output_'].Update(start_string)

window.close()




# https://green-house.bandcamp.com/album/music-for-living-spaces
# https://kareemali19.bandcamp.com/track/lesser-speeds-2
# https://carolabaer.bandcamp.com/album/the-story-of-valerie


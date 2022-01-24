#!/usr/bin/env conda run -n base python

# this uses pandas 
def bc_counter(tracks = None):
    from urllib.parse import urlsplit
    from urllib.request import urlopen
    import json
    import requests
    from bs4 import BeautifulSoup
    import pandas as pd
    import validators
    track_list = tracks 

    if track_list is None:
        print('\n********** NO LINKS!!! **********\n')
    elif len(track_list) == 0:
        print('\n********** NO LINKS!!! **********\n')

    #check if all links are formed properly
    elif all(validators.url(elem) for elem in track_list):
        try:
            all(urlopen(url).getcode() == 200 for url in track_list)
        except Exception as e:
            print("hmmm, something happened:", e)
            return "FAILD TO CONNECT TO SOME"
        print('\n********** GOT ALL LINKS **********\n')


        # WEB SCRAPING the links from each track
        super_fan_list = []
        for get_link in track_list:
            link=urlsplit(get_link)

            base_link=f'{link.scheme}://{link.netloc}'
            post_link=f"{base_link}/api/tralbumcollectors/2/thumbs"

            with requests.session() as s:
                res = s.get(get_link)
                soup = BeautifulSoup(res.text, 'lxml')

                track_title = soup.find('h2', {'class': 'trackTitle'}).text.strip()
                try:
                    track_title = track_title[:20]
                    # track title should be striped out of characters: the range (U+0000-U+FFFF) allowed by Tcl
                    char_list = [track_title[j] for j in range(len(track_title)) if ord(track_title[j]) in range(65536)]
                    track_title=''
                    for j in char_list:
                        track_title=track_title+j
                except Exception as e:
                    return e
                print(f'SEARCHING FOR FAN LIST OF THE TRACK ==> {track_title}')

                # session/json post for lazy loading, help from diggusbickus
                # the data for tralbum_type and tralbum_id are stored in a script attribute
                key="data-band-follow-info"
                data=soup.select_one(f'script[{key}]')[key]
                data=json.loads(data)
                open_more = {
                    "tralbum_type":data["tralbum_type"],
                    "tralbum_id":data["tralbum_id"],
                    "count":2000} # ridiculous number

                r=s.post(post_link, json=open_more).json()
                print('TOTAL FOUND FANS OF THE TRACK : ',len(r['results']))       
                # getting links NEW WAY through requests.sessions.post.json() 
                fan_list = []
                
                for result in r['results']:
                    fan_list.append(result['url'])
                super_fan_list.append({'track_name': track_title, 'track_fans': fan_list})

        # Sort and count matches (this is only needed if i wanted to do everything in python w/o pandas)
        super_fan_list.sort(key=lambda x: len(x['track_fans']))

        df = pd.DataFrame(super_fan_list)
        df = df.explode('track_fans')
        
        start_string = '*' *8
        print(start_string,'FANS THAT BOUGHT MORE THAN JUST 1 TRACK', start_string)
        fans= df.track_fans.value_counts()
        print('FANS THAT BOUGHT MORE THAN JUST 1 TRACK: ', fans[fans>1].shape[0] )

        # preparing final df 
        combo_fans = fans[fans>1]

        fan_tracks = []
        for fan in combo_fans.index:
            fan_tracks.append(
                df.loc[df.track_fans == fan, 'track_name'].values)

        final_df = pd.DataFrame({'track_fans':combo_fans.index, 'fans_combo':combo_fans, 
            'combo_tracks': fan_tracks}).reset_index(drop=True)
        
        final_groups = final_df.explode('combo_tracks').groupby(
            ['track_fans', 'fans_combo', 'combo_tracks']).count().sort_index(level = 1, ascending=False)

        
        return final_df # need to reset index to print out in a pretty way 

    else:
        print('\n********** One/some of the links are not correct **********\n')




# # # Lesser speed 
track_list = [
    'https://kareemali19.bandcamp.com/track/lesser-speeds-2',
    'https://carolabaer.bandcamp.com/album/the-story-of-valerie',
    'https://painsurprises.bandcamp.com/track/bout-de-bois?from=search&search_item_id=4108620026&search_item_type=t&search_match_part=%3F&search_page_id=1981433585&search_page_no=1&search_rank=1&search_sig=8356d47833c3814257e20bb867452e8c',
    'https://weirdnxc.bandcamp.com/album/act-4']


if __name__ == "__main__":
    import os
   # stuff only to run when not called via 'import' here
    data = bc_counter(track_list)


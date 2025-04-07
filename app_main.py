import streamlit as st
import requests
import time
from streamlit_option_menu import option_menu
from review_handler import review_form
import favorite_adder
from movie_details import show_movie_details  
from logger import log_movie_click
from movie_details import getWatched

# API Endpoints
ALL_MOVIES_API_URL = "http://localhost:8080/api/movies"
SEARCH_API_URL = "http://localhost:8080/api/search"

def fetch_all_movies(force_refresh=True):
    """Fetch all movies from API."""
    if "movies_data" not in st.session_state or force_refresh:
        try:
            response = requests.get(ALL_MOVIES_API_URL)
            if response.status_code == 200:
                st.session_state.movies_data = response.json()
            else:
                st.error(f"Error fetching movies: {response.status_code}")
                st.session_state.movies_data = []
        except Exception as e:
            st.error(f"Failed to connect to the API: {e}")
            st.session_state.movies_data = []
    
    return st.session_state.movies_data

def search_movies(keyword):
    """Fetch movies based on search keyword from the API"""
    if len(keyword) < 2:
        return []
    
    try:
        response = requests.get(SEARCH_API_URL, params={"keyword": keyword})
        if response.status_code == 200:
            return response.json()
        else:
            st.error(f"Error fetching search results: {response.status_code}")
            return []
    except Exception as e:
        st.error(f"Failed to connect to the API: {e}")
        return []

def fetch_movie_poster(movie_name):
    """Fetch movie poster from OMDB API"""
    OMDB_API_KEY = "2774b611"
    if not movie_name:
        return ""

    url = f"http://www.omdbapi.com/?t={movie_name}&apikey={OMDB_API_KEY}"
    try:
        response = requests.get(url).json()
        return response.get("Poster", "")
    except Exception as e:
        st.error(f"Error fetching poster for {movie_name}: {e}")
        return ""



def display_movie_cards(movies, title="🎬 Movies List"):
    """Display movie cards that are clickable, leading to movie details"""
    if not movies:
        st.warning("No movies found.")
        return

    st.title(title)

    cols = st.columns(2)  # Display in two columns

    user_id = st.session_state.get("user_id")

    for index, movie in enumerate(movies):
        if not isinstance(movie, dict):  # Ensure movie is a dictionary
            continue

        movie_id = movie.get("id", index)
        movie_name = movie.get("name", "Unknown")

        tempdto = getWatched(movie_id, user_id)  # Default to False if not set
        if tempdto:
            watched = tempdto.get('watched')
            userRating = tempdto.get('userRating')
            userReview = tempdto.get('userReview')
        else:
            watched = False
            userRating = None
            userReview = None

        with cols[index % 2]:  # Alternate between columns
            poster_url = fetch_movie_poster(movie_name)
            if poster_url:
                st.image(poster_url, width=200)

            # ✅ Clickable movie title button
            if st.button(movie_name, key=f"movie_{movie_id}"):
                st.session_state["selected_movie"] = movie
                log_movie_click(user_id, movie["id"])
                st.rerun()  # Refresh page to load movie details
                
            # ✅ Watched badge (Styled as a small tag at the top-right)
            watched_text = (
                '<div style="position: absolute; top: 10px; right: 10px; '
                'background-color: #4CAF50; color: white; padding: 5px 10px; '
                'border-radius: 15px; font-size: 12px;">✔ Watched</div>'
                if watched else 
                '<div style="position: absolute; top: 10px; right: 10px; '
                'background-color: #b0b0b0; color: white; padding: 5px 10px; '
                'border-radius: 15px; font-size: 12px;">⏳ Not Watched</div>'
            )

            # ✅ Movie Card with Watched Badge
            st.markdown(
                f"""
                <div style="position: relative; border-radius: 10px; padding: 15px; 
                            margin-bottom: 20px; background-color: #f0f0f0; padding-top: 10px;">
                    {watched_text}  <!-- Positioned at the top-right -->
                    <p><b>Category:</b> {movie.get('category', 'N/A')}</p>
                    <p><b>IMDB Rating:</b> ⭐ {movie.get('imdbrating', 'N/A')}</p>
                    <p><b>Release Date:</b> {movie.get('releaseDate', 'N/A')[:10]}</p>
                    <p><b>OTT Available:</b> {'✅ Yes' if movie.get('ottAvailable', False) else '❌ No'}</p>
                    <p>{movie.get('description', 'No description available.')}</p>
                    <p><b>User Rating:</b> 🔷 {userRating if userRating is not None else 'N/A'}</p>
                    <p><b>User Review:</b> {userReview if userReview else 'No review available.'}</p>
                </div>
                """, unsafe_allow_html=True
            )

            





def main():
    # If a movie is selected, show its details
    if "selected_movie" in st.session_state and st.session_state["selected_movie"]:
        show_movie_details(st.session_state["selected_movie"])
        return  

    # Sidebar Navbar
    with st.sidebar:
        menu_options = ["Home", "Trending", "Watchlist", "Favorites"]
        menu_icons = ["house", "fire", "list-task", "heart"]

        if st.session_state.get("role") == "ADMIN":
            menu_options.append("Admin Panel")
            menu_icons.append("shield-lock")

        selected = option_menu(
            menu_title="Movie Tracker",
            options=menu_options,
            icons=menu_icons,
            menu_icon="film",
            default_index=0
        )

    # ✅ Home Page (Includes Search Bar)
    if selected == "Home":
        st.title("🎥 Welcome to Movie Tracker")
        
        # ✅ Integrated Search Bar
        search_query = st.text_input("🔍 Search for a movie based on name, description and genre:", value="", max_chars=50)

        if search_query and len(search_query) >= 2:
            time.sleep(0.5)  # Prevents excessive API calls
            movies = search_movies(search_query)
            display_movie_cards(movies, title="🎬 Search Results")
        else:
            movies = fetch_all_movies(force_refresh=False)
            display_movie_cards(movies, title="🎬 All Movies")

    elif selected == "Trending":
        st.title("🔥 Trending Movies")
        st.write("What users have browsed")
        import trending_page
        trending_page.trending_page()

    elif selected == "Watchlist":
        st.title("📌 Your Watchlist")
        st.write("Track your movies here!")

    elif selected == "Favorites":
        import favorites_page
        favorites_page.favorites_page()

    elif selected == "Admin Panel":
        import admin_main
        admin_main.show_admin_dashboard()


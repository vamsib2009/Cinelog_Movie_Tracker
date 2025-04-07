import streamlit as st
import requests
import favorite_adder
from review_handler import review_form

OMDB_API_KEY = "2774b611"
VIEW_COUNT_API_URL = "http://localhost:8080/logging/get"

def fetch_movie_poster(movie_name):
    """Fetch movie poster from OMDB API"""
    if not movie_name:
        return ""
    
    url = f"http://www.omdbapi.com/?t={movie_name}&apikey={OMDB_API_KEY}"
    try:
        response = requests.get(url).json()
        return response.get("Poster", "")
    except Exception as e:
        st.error(f"Error fetching poster for {movie_name}: {e}")
        return ""

def fetch_movie_stats(movie_id):
    """Fetch total views and favorite count for a movie."""
    if not isinstance(movie_id, int):
        st.error("Invalid movie ID. Must be an integer.")
        return "N/A", "N/A"
    
    try:
        response = requests.get(VIEW_COUNT_API_URL, params={"movieId": movie_id})
        
        if response.status_code == 200:
            data = response.json()
            if isinstance(data, list) and len(data) >= 2:
                return data[0], data[1], data[2]  # Total views, Favorite count, No Watched
            else:
                st.error("Unexpected response format from server.")
                return "N/A", "N/A"
        else:
            return "N/A", "N/A"
    except Exception as e:
        st.error(f"Error fetching stats: {e}")
        return "N/A", "N/A"


def show_movie_details(movie):
    """Display detailed movie page with improved UI"""
    
    user_id = st.session_state.get("user_id")
    movie_id = movie.get("id")
    tempdto = getWatched(movie_id, user_id)  # Default to False if not set
    if tempdto:
        watched = tempdto.get('watched')
        userRating = tempdto.get('userRating')
        userReview = tempdto.get('userReview')
    else:
        watched = False
        userRating = None
        userReview = None

    # Movie Title + Watched Status  
    st.markdown(f"""
        <h1 style='text-align: center; color: #FF5733; font-size: 2em; font-weight: bold;'>
            {movie.get('name', 'Unknown Movie')}
        </h1>
        <p style='text-align: center; font-size: 1.1em; color: {"#27ae60" if watched else "#e74c3c"};'>
            {"✅ Watched" if watched else "🕶️ Not Watched"}
        </p>
    """, unsafe_allow_html=True)
    
    poster_url = fetch_movie_poster(movie.get("name"))
    total_views, favorite_count, no_watched = fetch_movie_stats(movie_id)

    col1, col2 = st.columns([1, 2])
    
    with col1:
        if poster_url:
            st.image(poster_url, width=280)

    with col2:
        st.markdown(f"""
            <div style='background-color: #f8f9fa; padding: 15px; border-radius: 10px;'>
                <p><b>Category:</b> {movie.get('category', 'N/A')}</p>
                <p><b>IMDB Rating:</b> ⭐ {movie.get('imdbrating', 'N/A')}</p>
                <p><b>Release Date:</b> {movie.get('releaseDate', 'N/A')[:10]}</p>
                <p><b>OTT Available:</b> {'✅ Yes' if movie.get('ottAvailable', False) else '❌ No'}</p>
                <p><b>Description:</b> {movie.get('description', 'No description available.')}</p>
                <p><b>User Rating:</b> 🔷 {userRating if userRating is not None else 'N/A'}</p>
                <p><b>User Review:</b> {userReview if userReview else 'No review available.'}</p>
            </div>
        """, unsafe_allow_html=True)

    # 🎥 **Views & Favorites Display**
    st.markdown(f"""
        <div style='display: flex; justify-content: center; gap: 15px; margin-top: 10px;'>
            <div style='background-color: #222; color: #fff; padding: 8px 15px; 
                        border-radius: 10px; font-size: 16px; min-width: 140px; text-align: center;'>
                🔍 {total_views} Page Views
            </div>
            <div style='background-color: #222; color: #fff; padding: 8px 15px; 
                        border-radius: 10px; font-size: 16px; min-width: 140px; text-align: center;'>
                ❤️ {favorite_count} Favorited
            </div>
            <div style='background-color: #222; color: #fff; padding: 8px 15px; 
                        border-radius: 10px; font-size: 16px; min-width: 140px; text-align: center;'>
                👁️ {no_watched} Watched
            </div>
        </div>
    """, unsafe_allow_html=True)

    st.markdown("""<hr style='border:1px solid #ddd; margin-top: 20px;'>""", unsafe_allow_html=True)

    col3, col4, col5, col6 = st.columns([1, 1, 1, 1])  
    
    # ❤️ **Add to Favorites Button**
    with col3:
        if st.button("❤️ Add to Favorites", key=f"fav_{movie_id}"):
            favorite_adder.add_to_favorites(st.session_state.get("user_id"), movie_id)
            st.success(f"Added to Favorites!")

    # ✍️ **Write/Edit Review Button**
    with col4:
        button_label = "✏️ Edit Review" if movie.get("userReview") else "✍️ Write a Review"
        if st.button(button_label, key=f"review_{movie_id}"):
            st.session_state["active_review"] = movie_id

    # 🕶️ **Watched Toggle Button**
    with col5:
        toggle_label = "🔄 Mark as Unwatched" if watched else "🎬 Mark as Watched"
        if st.button(toggle_label, key=f"watched_{movie_id}"):
            toggleWatched(movie_id, not watched, user_id)
            st.rerun()

    # 🔙 **Back to Home Button**
    with col6:
        if st.button("🔙 Back to Home", key="back_home"):
            del st.session_state["selected_movie"]
            st.rerun()

    # Display Review Form If Active
    if st.session_state.get("active_review") == movie_id:
        review_form(movie)


def getWatched(movie_id, user_id):
    """Send a request to fetch whether the movie is watched or not"""
    
    response = requests.get("http://localhost:8080/watched/getwatched", params={"userId": user_id, "movieId": movie_id})
    
    if response.status_code == 200:
        return response.json()
    else:
        st.error("Failed to update status!")

def toggleWatched(movie_id, current_status, user_id):
    """Send a request to update the watched status in the backend"""

    response = requests.put("http://localhost:8080/watched/toggle",
                            params={"movieId": movie_id, "userId": user_id})

    if response.status_code == 200:
        watched = getWatched(movie_id, user_id)
        st.rerun()
    else:
        st.error("Failed to update status!")



def display_movie_cards(movies, title="🎬 Movies List"):
    """Display clickable movie cards"""
    if not movies:
        st.warning("No movies found.")
        return
    
    st.title(title)
    cols = st.columns(2)
    
    for index, movie in enumerate(movies):
        movie_id = movie.get("id")
        movie_name = movie.get("name", "Unknown")
        
        with cols[index % 2]:
            poster_url = fetch_movie_poster(movie_name)
            if poster_url:
                st.image(poster_url, width=200)
            
            if st.button(f"📽️ {movie_name}", key=f"movie_{movie_id}"):
                st.session_state["selected_movie"] = movie
                st.rerun()
    
    if "selected_movie" in st.session_state:
        st.experimental_set_query_params(movie=st.session_state["selected_movie"]["id"])
        show_movie_details(st.session_state["selected_movie"])
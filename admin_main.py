import streamlit as st
import requests

# API Endpoint for adding movies
ADD_MOVIE_API_URL = "http://localhost:8080/api/addmovie"

def show_admin_dashboard():
    st.title("🛠 Admin Panel")

    # Button to trigger movie addition form
    if st.button("➕ Add New Movie"):
        st.session_state["show_add_movie_form"] = True  # Set session state to show form

    if st.button("📊 Get User Dashboard"):
        st.session_state["get_user_dashboard"] = True


    # Movie addition form
    if st.session_state.get("show_add_movie_form", False):
        st.subheader("🎬 Add a New Movie")

        # Movie input fields
        movie_name = st.text_input("Movie Name", "")
        category = st.text_input("Category", "")
        imdb_rating = st.number_input("IMDB Rating", min_value=0.0, max_value=10.0, step=0.1)
        release_date = st.date_input("Release Date")
        ott_available = st.checkbox("Available on OTT Platforms?")
        description = st.text_area("Movie Description")

        col1, col2 = st.columns(2)  # Two columns for buttons

        with col1:
            # Submit button
            if st.button("✅ Submit Movie"):
                movie_data = {
                    "name": movie_name,
                    "category": category,
                    "imdbrating": imdb_rating,
                    "releaseDate": str(release_date),
                    "ottAvailable": ott_available,
                    "description": description,
                }

                # Send the data to the backend API
                response = requests.post(ADD_MOVIE_API_URL, json=movie_data)

                if response.status_code == 200:
                    st.success("🎉 Movie added successfully!")
                    st.session_state["show_add_movie_form"] = False  # Hide form after submission
                else:
                    st.error(f"❌ Failed to add movie: {response.text}")

        with col2:
            # Close form button
            if st.button("❌ Close Form"):
                st.session_state["show_add_movie_form"] = False  # Hide form without submitting
                st.rerun()  # Refresh UI to reflect the change

# If this file is run directly, show the admin panel
if __name__ == "__main__":
    show_admin_dashboard()

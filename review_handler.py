import streamlit as st
import requests

# API Endpoint
SUBMIT_REVIEW_API_URL = "http://localhost:8080/watched/updaterating"

def submit_review(movie_id, user_rating, user_review):
    """Submit user review and rating to the backend"""
    
    # ✅ Debugging: Ensure function is being called
    st.toast("Submitting review...")  # Visual confirmation
    print("DEBUG: submit_review() function triggered")  

    if user_rating is None or user_review.strip() == "":
        st.warning("Please provide both a rating and a review before submitting.")
        return

    payload = {
        "userId": st.session_state.get("user_id"),
        "movieId": movie_id,
        "userRating": user_rating,
        "userReview": user_review
    }

    # ✅ Debugging: Ensure payload is correct
    st.write("Debug Payload:", payload)
    print(f"DEBUG: Sending payload: {payload}")  

    try:
        response = requests.put(SUBMIT_REVIEW_API_URL, json=payload)
        print(f"DEBUG: Response received - Status: {response.status_code}, Body: {response.text}")  # ✅ Debugging print

        if response.status_code == 200:
            st.success("Review submitted successfully!")
            # ✅ Trigger Streamlit rerun to update the UI
            st.rerun()

        else:
            st.error(f"Error submitting review: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"DEBUG: API connection failed - {e}")  # ✅ Debugging print
        st.error(f"Failed to connect to the API: {e}")

import streamlit as st

def review_form(movie):
    """Display the user review and rating form with session state handling"""

    st.subheader(f"Add Your Review for {movie.get('name', 'Unknown')}")

    existing_review = movie.get('userReview', '')  # Fetch existing review if any
    button_label = "✏️ Edit Review" if existing_review else "✍️ Write Review"

    with st.form(key=f"review_form_{movie['id']}"):
        user_rating = st.slider("Rating (out of 10)", 0.0, 10.0, step=0.1, value=5.0)
        user_review = st.text_area("Write your review:", value=existing_review or "")

        col1, col2 = st.columns([1, 1])  # Create two buttons side-by-side

        with col1:
            submit = st.form_submit_button(button_label)  # Dynamic submit button

        with col2:
            cancel = st.form_submit_button("❌ Cancel")  # Cancel button

        if submit:
            print("DEBUG: Submit button clicked")  # ✅ Debugging print
            st.toast("Submitting... Please wait!")  # ✅ Visual confirmation
            submit_review(movie["id"], user_rating, user_review)
            st.rerun()

        if cancel:
            print("DEBUG: Cancel button clicked")  # ✅ Debugging print
            st.session_state["active_review"] = None  # Remove active review
            st.rerun()



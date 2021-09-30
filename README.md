# iOS_U.O.ME
Finance Tracking App


Anderson Jeronimo

Owen Ricketts

Chrsitie Chen

Jiwoo Seo





U.O.ME is a finance tracking app that helps users manage their personal and group purchases. 


Functionalities and how to use them:


Registering new users: Users can not have duplicate email addresses or usernames, users must have a profile image. Firebase Authentication manages user registering/login processes, while the database manages username/profile image url (url of firebase storage) and other personal information such as added groups and personal receipts.


Login: Users must have already registered, the app automatically logs in on load provided that the user did not log out previously. The currently logged in user is retrieved through Firebase Authentication. The profile image is displayed as it fetches profile image url from database and displays url as an image.


Profile Page: The profile page displays the profile picture and username of the currently logged in user. The user’s list of friends is shown, along with a dollar amount of what that user owes his or her friends. A positive amount means that the user owes his or her friend, and a negative amount means that the friend owes the user. A user can click the plus button next to the friends label and open up a view controller to add more friends. A circle indicates that the user in the list is not a current friend, and a check indicates that the user is. After dismissing this view, the user can refresh the table to see their newly updated friends list. The amount next to each user is updated as new receipts are added. Refresh the table view to get the most recently updated. 


Personal: In the personal tab, there is a table view of the receipts that a user has uploaded. The user can swipe to delete, click on a row in the table view to edit a receipt, and click the “Add Expense” button on the navigation bar in the top right corner to add a new receipt to the database. Every time the personal view appears, the data for that individual is fetched from Firebase. Users can update their receipts after adding them.



Group: In the group tab, the user can see the list of groups that s/he is in as a table view. The name and the members of each group are displayed in each cell. The user can add a group and add members to it. Users can not delete groups; users can delete individual receipts, but there is no reason to delete the record of the group itself (so users can track who they’ve made purchases with). The users can update their receipts after adding them (merchant, date, etc…); however, the user can not change the total price. This way, the user can not “ask” for more money than previously agreed on by the group. At the time of adding, if either the image is not suitable for the API or the user would like to ask for more/less money than listed on the receipt, the user can adjust the total price to reflect what they would like. 


If the user is looking at a receipt that they uploaded, they also have the ability to change who has paid the receipt. However, they can not reverse this decision for a similar reason: the app tracks who has paid and has not paid, we do not want users to be able to erase the record of someone already paying for their portion of a receipt. The price as of now, is split evenly. We took into account Professor Sproull’s suggestion of letting the user “bypass” certain friends in the group; this function allows the uploader to mark someone has paid (even if they did not).


If the user looking at the receipt is not the person who uploaded it, they can not edit it and can only view it. 


Receipts that the currently logged in user has already paid are marked in blue, receipts that the user still has to pay are marked in orange, receipts that are uploaded by the user are in grey.





Hope you enjoy our app! Thank you.

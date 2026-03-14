# ERP Book ISBN Lookup Integration
----------------------------------

Integrating ISBN lookups into your ERP is a brilliant move—it saves librarians from manual data entry and keeps your database consistent. Since you are using a barcode scanner, the process is essentially automating a search query against a global database.

Here is the step-by-step roadmap to achieving this:

1. The Hardware Integration
A standard USB or Bluetooth barcode scanner acts as a Human Interface Device (HID). In simple terms, your computer treats it like a keyboard.

When a librarian clicks on an input field and scans a book, the scanner "types" the ISBN digits and usually hits "Enter" automatically.

Pro Tip: Ensure your input field is "autofocused" so they don't have to click it every time.

2. The Data Source (APIs)
To get the title and author, your ERP needs to talk to a book database. You don't want to build this database yourself; you want to use an API.

|Provider           |Pros                                               |Cost
|-------------------|---------------------------------------------------|---
|Google Books API   |"Massive database, very fast, easy to use."        |Free (with daily limits)
|Open Library API   |"Completely free, open-source spirit."             |Free
|ISBNDB             |"Extremely detailed (includes pricing, etc.)."     |Paid (Subscription)


## Workflow (Step-by-Step)
--------------------------
Here is the exact sequence of events when a librarian adds a new book:

Step 1: Scan ISBN
The librarian clicks "Add New Book" and scans the barcode (e.g., 978-0321765723).

Step 2: API Call
ERP backend sends this number to the Google Books API (or your chosen provider).

Example for Google Books: https://www.googleapis.com/books/v1/volumes?q=isbn:9780141036144

Step 3: Receive Data
The API responds with a JSON object containing the book's details:

{
  "title": "The C++ Programming Language",
  "authors": ["Bjarne Stroustrup"],
  "publisher": "Addison-Wesley",
  "publishedDate": "2013-05-09",
  "description": "The definitive guide to C++...",
  "pageCount": 1300,
  "categories": ["Computer Science"],
  "thumbnail": "http://books.google.com/books/content?id=..."
}
Step 4: Auto-Fill Form
Your ERP automatically populates the "Add New Book" form with this data.

Step 5: Librarian Review
The librarian quickly verifies the details and adds the specific copy information (Barcode ID, Condition, Location).

Step 6: Save to Database
When they click "Save", the data goes into your ERP's lib_books and lib_book_copies tables.


### Implementation Example (JavaScript/Pseudo-code)
If you are building the web-based part of your ERP, the logic looks a bit like this:

```javascript
async function getBookDetails(isbn) {
  const response = await fetch(`https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`);
  const data = await response.json();

  if (data.totalItems > 0) {
    const book = data.items[0].volumeInfo;
    // Map API data to your ERP fields
    document.getElementById('titleField').value = book.title;
    document.getElementById('authorField').value = book.authors.join(', ');
    document.getElementById('publisherField').value = book.publisher;
  } else {
    alert("Book not found. Please enter details manually.");
  }
}
```

### Important Considerations

ISBN-10 vs ISBN-13: Modern books use 13 digits, but older ones use 10. Ensure your database and logic can handle both.

Manual Fallback: No database is perfect. Always allow the librarian to edit the info or type it in manually if the scan fails to find a match.

Local Caching: Once a book is scanned and saved in your ERP, you should store that data in your own SQL/NoSQL database so you don't have to call the external API for that same book ever again.

### How to implement this in Laravel
------------------------------------

the best approach is to create a Service Class. This keeps your controller clean and allows you to reuse the logic elsewhere in your ERP.

Laravel provides a built-in HTTP Client (a wrapper around Guzzle) that makes this very simple.

1. Set up your Environment
First, add your Google API Key to your .env file. You can get a key for free from the Google Cloud Console.

GOOGLE_BOOKS_API_KEY=your_api_key_here

2. Create the Book Service
Create a new file at app/Services/BookApiService.php. This class will handle the communication with Google.

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class BookApiService
{
    public function getDetailsByIsbn($isbn)
    {
        $apiKey = config('services.google_books.key');
        $url = "https://www.googleapis.com/books/v1/volumes";

        try {
            $response = Http::get($url, [
                'q' => 'isbn:' . $isbn,
                'key' => $apiKey,
            ]);

            if ($response->successful() && isset($response['items'][0])) {
                $bookData = $response['items'][0]['volumeInfo'];

                return [
                    'success' => true,
                    'title'   => $bookData['title'] ?? 'N/A',
                    'authors' => isset($bookData['authors']) ? implode(', ', $bookData['authors']) : 'Unknown Author',
                    'publisher' => $bookData['publisher'] ?? 'N/A',
                    'published_date' => $bookData['publishedDate'] ?? 'N/A',
                    'description' => $bookData['description'] ?? '',
                    'thumbnail' => $bookData['imageLinks']['thumbnail'] ?? null,
                ];
            }

            return ['success' => false, 'message' => 'Book not found.'];

        } catch (\Exception $e) {
            Log::error("Google Books API Error: " . $e->getMessage());
            return ['success' => false, 'message' => 'API connection failed.'];
        }
    }
}
```
3. Register the Service (Optional but Recommended)
Add the configuration to config/services.php so Laravel knows where to find your key:

```php
'google_books' => [
    'key' => env('GOOGLE_BOOKS_API_KEY'),
],
```

4. Create the Controller
Now, create a controller to handle the scan request from your Library module frontend.

```php
namespace App\Http\Controllers;

use App\Services\BookApiService;
use Illuminate\Http\Request;

class LibraryController extends Controller
{
    protected $bookService;

    public function __construct(BookApiService $bookService)
    {
        $this->bookService = $bookService;
    }

    public function fetchBookByIsbn(Request $request)
    {
        $isbn = $request->query('isbn');
        
        if (!$isbn) {
            return response()->json(['error' => 'ISBN is required'], 400);
        }

        $result = $this->bookService->getDetailsByIsbn($isbn);

        return response()->json($result);
    }
}
```

## How it works in our ERP:
---------------------------

Scanner Input: In your "Add New Book" view, create an input field. When the librarian scans the barcode, the scanner "types" the ISBN and hits Enter.

AJAX Request: Use JavaScript to detect that Enter key, take the ISBN, and send it to your new Laravel route (e.g., /library/fetch-book?isbn=12345).

Auto-Fill: The controller returns the JSON (Title, Author, etc.), and your JavaScript populates the other form fields instantly.

Pro-Tip: Data Sanitization
Since barcode scanners can sometimes add a prefix or suffix, use $isbn = preg_replace('/\D/', '', $isbn); in your service to ensure you are only sending digits to Google.

Learn how to retrieve book details with Google Books API

This video provides a practical walkthrough of connecting to the Google Books API and handling the JSON response, which is the core logic you'll need to implement in your Laravel service.



## What all API are there to use free of cost


Here is a curated list of the best **free** APIs for fetching book details by ISBN, along with their key features and limitations.

### 1. Open Library API
Open Library is a project by the Internet Archive, aiming to create a web page for every book ever published. It is one of the most comprehensive open-source book databases.

*   **URL**: `https://openlibrary.org/dev/docs/api/books`
*   **Endpoint**: `https://openlibrary.org/api/books?bibkeys=ISBN:[ISBN]&format=json&jscmd=data`
*   **Pros**:
    *   Completely free and open-source.
    *   Massive database with millions of records.
    *   Includes metadata like cover images, subjects, and editions.
*   **Cons**:
    *   Response time can sometimes be slow.
    *   Data quality depends on user contributions, so some records might be incomplete.

### 2. Google Books API
While Google Books is a commercial service, its API offers a generous free tier that is more than sufficient for most applications.

*   **URL**: `https://developers.google.com/books/docs/v1/using-volumes`
*   **Endpoint**: `https://www.googleapis.com/books/v1/volumes?q=isbn:[ISBN]`
*   **Pros**:
    *   Very fast and reliable.
    *   Excellent data quality and coverage.
    *   Provides book previews and links to purchase.
*   **Cons**:
    *   Requires an API key (though free to obtain).
    *   Strict rate limits (10,000 queries per day).

### 3. Goodreads API (Unofficial)
Goodreads is a popular social cataloging website. While they don't have an official public API anymore, the community has reverse-engineered one that works well.

*   **URL**: `https://github.com/sgratch/ GoodreadsAPI`
*   **Endpoint**: `https://www.goodreads.com/book/isbn/[ISBN]`
*   **Pros**:
    *   Rich metadata including ratings, reviews, and genre tags.
    *   Large user base ensures good coverage.
*   **Cons**:
    *   Unofficial, so it might break if Goodreads changes its site structure.
    *   Can be rate-limited if used heavily.

### 4. LibraryThing API
LibraryThing is a social cataloging website for book lovers. Their API is free for non-commercial use.

*   **URL**: `https://www.librarything.com/dev/api`
*   **Endpoint**: `https://www.librarything.com/dev/rest.php?method=library.getBooksByISBN&isbn=[ISBN]`
*   **Pros**:
    *   Good for cataloging and library management applications.
    *   Provides detailed book information.
*   **Cons**:
    *   Requires an API key.
    *   May have stricter rate limits than others.

### 5. Amazon Product Advertising API (Limited Free Use)
While primarily a commercial API, Amazon allows limited free usage for developers who are part of their Associates program.

*   **URL**: `https://associates.amazon.com/help/operating/api`
*   **Endpoint**: Varies based on the Product Advertising API version.
*   **Pros**:
    *   Extremely comprehensive data including pricing and availability.
    *   High data accuracy.
*   **Cons**:
    *   Requires approval for the Associates program.
    *   Complex authentication process.
    *   Strict usage limits.

### Summary Table

| API | Free Tier | Best For | Data Quality | Ease of Use |
|-----|-----------|----------|--------------|-------------|
| **Open Library** | Yes | Open-source projects | Medium | Easy |
| **Google Books** | Yes (with key) | General purpose | High | Very Easy |
| **Goodreads** | Yes (unofficial) | Social features | High | Easy |
| **LibraryThing** | Yes (non-commercial) | Library management | Medium | Medium |
| **Amazon PA API** | Limited | Commercial apps | Very High | Complex |

### Recommendation for Your ERP
For your ERP system, I recommend using **Google Books API** as the primary source due to its reliability and ease of use. You can use **Open Library API** as a fallback if the book is not found in the Google Books database.

This combination will give you the best balance of data quality, availability, and ease of implementation.


### One Small Tip for your Frontend:
When you receive the cover URL from the API, display it as a small preview next to the form. It helps the librarian visually confirm they scanned the right book!


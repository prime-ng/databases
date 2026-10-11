
To make this work seamlessly, you need a small piece of JavaScript (using Axios, which comes standard with Laravel) to listen for the scanner and update your form fields without refreshing the page.

1. The Blade View (HTML)
In your Library module's "Add Book" page, ensure your input IDs match the keys in your JavaScript.

```html
<div class="form-group">
    <label>Scan ISBN</label>
    <input type="text" id="isbn_input" class="form-control" placeholder="Scan barcode..." autofocus>
    <div id="loader" style="display:none;">Searching...</div>
</div>

<hr>

<div class="form-group">
    <label>Book Title</label>
    <input type="text" id="title" class="form-control">
</div>

<div class="form-group">
    <label>Author</label>
    <input type="text" id="author" class="form-control">
</div>

<div class="form-group">
    <label>Publisher</label>
    <input type="text" id="publisher" class="form-control">
</div>

<div id="cover_preview" style="margin-top: 10px;"></div>
```

2. The JavaScript (Vanilla JS + Axios)
Add this to your script section. It listens for the Enter key (which most scanners send automatically after a scan).

```javascript

document.getElementById('isbn_input').addEventListener('keypress', function (e) {
    if (e.key === 'Enter') {
        e.preventDefault(); // Stop the form from submitting normally
        
        let isbn = this.value;
        let loader = document.getElementById('loader');
        
        if (isbn.length < 10) return; // Basic validation

        loader.style.display = 'block';

        // Call your Laravel Route
        axios.get(`/library/fetch-book?isbn=${isbn}`)
            .then(response => {
                loader.style.display = 'none';
                let data = response.data;

                if (data.success) {
                    // Auto-fill the fields
                    document.getElementById('title').value = data.title;
                    document.getElementById('author').value = data.author;
                    document.getElementById('publisher').value = data.publisher;
                    
                    // Show Cover Image
                    if (data.cover) {
                        document.getElementById('cover_preview').innerHTML = 
                            `<img src="${data.cover}" width="100" class="img-thumbnail">`;
                    }
                    
                    // Clear the scan input for the next book
                    document.getElementById('isbn_input').value = '';
                } else {
                    alert('Book details not found. Please enter manually.');
                }
            })
            .catch(error => {
                loader.style.display = 'none';
                console.error('Error fetching book:', error);
            });
    }
});
```

3. The Route (web.php)
Don't forget to define the route that connects the JavaScript to your Controller.

```php
use App\Http\Controllers\LibraryController;

Route::get('/library/fetch-book', [LibraryController::class, 'fetchBookByIsbn']);
```

4. The Controller Method (LibraryController.php)
This is the "brain" that talks to the API.

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\BookApiService;

class LibraryController extends Controller
{
    protected $bookApi;

    public function __construct(BookApiService $bookApi)
    {
        $this->bookApi = $bookApi;
    }

    public function fetchBookByIsbn(Request $request)
    {
        $isbn = $request->input('isbn');
        
        // Call the service we created earlier
        $bookData = $this->bookApi->getDetailsByIsbn($isbn);

        return response()->json($bookData);
    }
}
```

5. The Service (BookApiService.php)
(I'll paste this again here for completeness, but you already have it in your project).

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class BookApiService
{
    public function getDetailsByIsbn($isbn)
    {
        // 1. Try Google Books First
        $book = $this->searchGoogleBooks($isbn);

        // 2. If Google fails or finds nothing, try Open Library
        if (!$book) {
            $book = $this->searchOpenLibrary($isbn);
        }

        return $book ? array_merge(['success' => true], $book) : ['success' => false, 'message' => 'Book not found in any database.'];
    }

    private function searchGoogleBooks($isbn)
    {
        $response = Http::get("https://www.googleapis.com/books/v1/volumes", [
            'q' => 'isbn:' . $isbn,
            'key' => config('services.google_books.key'),
        ]);

        if ($response->successful() && isset($response['items'][0])) {
            $data = $response['items'][0]['volumeInfo'];
            return [
                'source' => 'Google',
                'title' => $data['title'] ?? 'Unknown',
                'author' => isset($data['authors']) ? implode(', ', $data['authors']) : 'Unknown',
                'publisher' => $data['publisher'] ?? 'N/A',
                'cover' => $data['imageLinks']['thumbnail'] ?? null,
            ];
        }
        return null;
    }

    private function searchOpenLibrary($isbn)
    {
        // Open Library uses a specific key format: ISBN:978...
        $url = "https://openlibrary.org/api/books?bibkeys=ISBN:{$isbn}&format=json&jscmd=data";
        $response = Http::get($url);

        if ($response->successful() && isset($response["ISBN:{$isbn}"])) {
            $data = $response["ISBN:{$isbn}"];
            return [
                'source' => 'OpenLibrary',
                'title' => $data['title'] ?? 'Unknown',
                'author' => isset($data['authors']) ? collect($data['authors'])->pluck('name')->implode(', ') : 'Unknown',
                'publisher' => isset($data['publishers']) ? $data['publishers'][0]['name'] : 'N/A',
                'cover' => $data['cover']['medium'] ?? null,
            ];
        }
        return null;
    }
}
```

6. The Configuration (config/services.php)
Add your Google API Key here.

```php
'google_books' => [
    'key' => env('GOOGLE_BOOKS_API_KEY'),
],
```

How it works:

Scanner scans ISBN.

JavaScript detects Enter key.

Axios sends request to your Laravel backend.

BookApiService checks Google Books.

If not found, checks Open Library.

Returns data to JavaScript.

JavaScript fills the form fields automatically.

Librarian just clicks "Save"!


### Tips for "Pro" Library UX:

Autofocus: When the page loads, use document.getElementById('isbn_input').focus(); so the librarian can start scanning immediately without clicking.

Sound Feedback: You can add a small "Beep" sound in the .then() block of your JavaScript. It lets the librarian know the data was found successfully without looking at the screen.

Cleaning the ISBN: Scanners sometimes add characters. In your Controller, use $isbn = preg_replace("/[^0-9X]/i", "", $isbn); to make sure you only send the clean ISBN to the APIs.


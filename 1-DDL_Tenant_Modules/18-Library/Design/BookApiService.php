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

//
//  StorageManager.swift
//  MessengerApp
//
//  Created by Emil on 17.01.2023.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /image/emil-emper-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    
    public func uploadPictureProfile(with data: Data, fileName: String,  completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metaData, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.faildeToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                //failed
                print("failde to get download url")
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
                }
                
                let urlString = url.absoluteString
                print("download url returned \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    
    public enum StorageErrors: Error {
        case faildeToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadUrl(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        }
    }
}

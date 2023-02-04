//
//  StorageManager.swift
//  MessengerApp
//
//  Created by Emil on 17.01.2023.
//

import Foundation
import FirebaseStorage
import SwiftUI


/// Allow you to  get, fetch, and upload files to firebase storage
final class StorageManager {
    
    static let shared = StorageManager()
    
   
    
    private let storage = Storage.storage().reference()
    
    /*
     /image/emil-emper-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    
    ///upload picture to firebase storege end returns completion with url string to download
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
    
    
    ///upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String,  completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] metaData, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.faildeToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL { url, error in
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
    
    
    ///upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String,  completion: @escaping UploadPictureCompletion) {
        
        
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] metaDataa, error in
            guard error == nil else {
                //failed
                print("failed to upload videoFile to firebase")
                completion(.failure(StorageErrors.faildeToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL { url, error in
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

import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class AttachmentsDisplayFeature {
  /// Build materials section
  Widget buildMaterialsSection({
    required BuildContext context,
    required List<Map<String, String>> selectedMaterials,
    required Function(int) onRemoveMaterial,
  }) {
    if (selectedMaterials.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_books, size: 18, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text(
                'المواد المرفقة:',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          ...selectedMaterials.asMap().entries.map((entry) {
            final index = entry.key;
            final material = entry.value;
            return Container(
              margin: EdgeInsets.only(
                bottom: Responsive.space(context, size: Space.tiny),
              ),
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.small),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.small),
                ),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.blue[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      material['title'] ?? '',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16),
                    color: Colors.red[400],
                    onPressed: () => onRemoveMaterial(index),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build new attachments section
  Widget buildNewAttachmentsSection({
    required BuildContext context,
    required List<Map<String, String>> uploadedFiles,
    required List<Map<String, String>> uploadedImages,
    required List<Map<String, String>> addedLinks,
    required Function(int) onRemoveFile,
    required Function(int) onRemoveImage,
    required Function(int) onRemoveLink,
  }) {
    if (uploadedFiles.isEmpty && uploadedImages.isEmpty && addedLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, size: 18, color: Colors.green[700]),
              SizedBox(width: 8),
              Text(
                'المرفقات الجديدة:',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),

          // Display uploaded images
          if (uploadedImages.isNotEmpty) ...[
            ...uploadedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return _buildAttachmentItem(
                context: context,
                title: image['title'] ?? '',
                icon: Icons.image,
                iconColor: Colors.blue[600]!,
                borderColor: Colors.blue[100]!,
                onRemove: () => onRemoveImage(index),
              );
            }),
          ],

          // Display uploaded files
          if (uploadedFiles.isNotEmpty) ...[
            ...uploadedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildAttachmentItem(
                context: context,
                title: file['title'] ?? '',
                icon: Icons.upload_file,
                iconColor: Colors.green[600]!,
                borderColor: Colors.green[100]!,
                onRemove: () => onRemoveFile(index),
              );
            }),
          ],

          // Display added links
          if (addedLinks.isNotEmpty) ...[
            ...addedLinks.asMap().entries.map((entry) {
              final index = entry.key;
              final link = entry.value;
              print('🔗 [AttachmentsDisplay] Rendering link $index: $link');
              return _buildAttachmentItem(
                context: context,
                title: link['title'] ?? '',
                icon: Icons.link,
                iconColor: Colors.orange[600]!,
                borderColor: Colors.orange[100]!,
                onRemove: () => onRemoveLink(index),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Build individual attachment item
  Widget _buildAttachmentItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.tiny),
      ),
      padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            color: Colors.red[400],
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build action buttons section with direct attachment options
  Widget buildActionButtons({
    required BuildContext context,
    required VoidCallback onAddMaterials,
    required VoidCallback onAddImage,
    required VoidCallback onAddFile,
    required VoidCallback onAddLink,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'إضافة مرفق',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // Add Materials Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddMaterials,
              icon: Icon(Icons.library_books),
              label: Text('من الماتيريال الموجودة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                side: BorderSide(color: Colors.black, width: 1),
              ),
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          // New attachments row - circular outlined icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Image button
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green[600]!, width: 2),
                    ),
                    child: IconButton(
                      onPressed: onAddImage,
                      icon: Icon(
                        Icons.image,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  Text(
                    'صورة',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // File button
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green[600]!, width: 2),
                    ),
                    child: IconButton(
                      onPressed: onAddFile,
                      icon: Icon(
                        Icons.upload_file,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  Text(
                    'ملف',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Link button
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green[600]!, width: 2),
                    ),
                    child: IconButton(
                      onPressed: onAddLink,
                      icon: Icon(
                        Icons.link,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  Text(
                    'رابط',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
        ],
      ),
    );
  }
}

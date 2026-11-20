using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Media;

namespace BirdNETGoControl
{
    public static class Flags
    {
        private static readonly Dictionary<string, ImageSource> Cache = new();

        public static ImageSource Get(string code)
        {
            if (Cache.TryGetValue(code, out var cached)) return cached;
            var g = new DrawingGroup();
            Build(code ?? "en", g);
            var img = new DrawingImage(g);
            img.Freeze();
            Cache[code ?? "en"] = img;
            return img;
        }

        private static SolidColorBrush Br(string hex)
        {
            var b = new SolidColorBrush((Color)ColorConverter.ConvertFromString(hex));
            b.Freeze();
            return b;
        }

        private static void Box(DrawingGroup g, string hex, double x, double y, double w, double h)
            => g.Children.Add(new GeometryDrawing(Br(hex), null, new RectangleGeometry(new Rect(x, y, w, h))));

        private static void Poly(DrawingGroup g, string hex, string outline, params Point[] pts)
        {
            var fig = new PathFigure { StartPoint = pts[0], IsClosed = true };
            for (int i = 1; i < pts.Length; i++) fig.Segments.Add(new LineSegment(pts[i], true));
            var geo = new PathGeometry();
            geo.Figures.Add(fig);
            g.Children.Add(new GeometryDrawing(Br(hex),
                outline == null ? null : new Pen(Br(outline), 0.7), geo));
        }

        private static void Disc(DrawingGroup g, string hex, double cx, double cy, double r)
            => g.Children.Add(new GeometryDrawing(Br(hex), null, new EllipseGeometry(new Point(cx, cy), r, r)));

        private static void Slash(DrawingGroup g, string hex, double t, double x1, double y1, double x2, double y2)
        {
            var geo = new LineGeometry(new Point(x1, y1), new Point(x2, y2));
            g.Children.Add(new GeometryDrawing(null, new Pen(Br(hex), t), geo));
        }

        private static void H(DrawingGroup g, params string[] c)
        {
            double h = 20.0 / c.Length;
            for (int i = 0; i < c.Length; i++) Box(g, c[i], 0, i * h, 30, h + 0.01);
        }

        private static void V(DrawingGroup g, params string[] c)
        {
            double w = 30.0 / c.Length;
            for (int i = 0; i < c.Length; i++) Box(g, c[i], i * w, 0, w + 0.01, 20);
        }

        private static void Nordic(DrawingGroup g, string field, string cross, double t)
        {
            Box(g, field, 0, 0, 30, 20);
            Box(g, cross, 11 - t / 2, 0, t, 20);
            Box(g, cross, 0, 10 - t / 2, 30, t);
        }

        private static void Build(string c, DrawingGroup g)
        {
            switch (c)
            {
                case "cs":
                    Box(g, "#FFFFFF", 0, 0, 30, 10);
                    Box(g, "#D7141A", 0, 10, 30, 10);
                    Poly(g, "#11457E", null, new Point(0, 0), new Point(15, 10), new Point(0, 20));
                    break;
                case "da": Nordic(g, "#C8102E", "#FFFFFF", 4); break;
                case "de": H(g, "#000000", "#DD0000", "#FFCE00"); break;
                case "es":
                    Box(g, "#AA151B", 0, 0, 30, 5);
                    Box(g, "#F1BF00", 0, 5, 30, 10);
                    Box(g, "#AA151B", 0, 15, 30, 5);
                    Box(g, "#AA151B", 7.5, 7.5, 3, 5);
                    Box(g, "#F1BF00", 8.4, 8.6, 1.2, 2.8);
                    break;
                case "fi": Nordic(g, "#FFFFFF", "#003580", 5); break;
                case "fr": V(g, "#0055A4", "#FFFFFF", "#EF4135"); break;
                case "hu": H(g, "#CE2939", "#FFFFFF", "#477050"); break;
                case "it": V(g, "#008C45", "#F4F5F0", "#CD212A"); break;
                case "lv":
                    Box(g, "#9E3039", 0, 0, 30, 8);
                    Box(g, "#FFFFFF", 0, 8, 30, 4);
                    Box(g, "#9E3039", 0, 12, 30, 8);
                    break;
                case "nb":
                    Box(g, "#BA0C2F", 0, 0, 30, 20);
                    Box(g, "#FFFFFF", 9.5, 0, 7, 20);
                    Box(g, "#FFFFFF", 0, 6.5, 30, 7);
                    Box(g, "#00205B", 11.25, 0, 3.5, 20);
                    Box(g, "#00205B", 0, 8.25, 30, 3.5);
                    break;
                case "nl": H(g, "#AE1C28", "#FFFFFF", "#21468B"); break;
                case "pl": H(g, "#FFFFFF", "#DC143C"); break;
                case "pt":
                    Box(g, "#046A38", 0, 0, 12, 20);
                    Box(g, "#DA291C", 12, 0, 18, 20);
                    Disc(g, "#FFE900", 12, 10, 4.6);
                    Disc(g, "#DA291C", 12, 10, 2.7);
                    Disc(g, "#FFFFFF", 12, 10, 1.3);
                    break;
                case "sk":
                    H(g, "#FFFFFF", "#0B4EA2", "#EE1C25");
                    Poly(g, "#EE1C25", "#FFFFFF",
                        new Point(6, 4.5), new Point(13, 4.5), new Point(13, 12),
                        new Point(9.5, 15.5), new Point(6, 12));
                    Box(g, "#FFFFFF", 9, 6, 1.2, 6.4);
                    Box(g, "#FFFFFF", 7.7, 7.6, 3.8, 1.1);
                    Box(g, "#FFFFFF", 8.3, 9.7, 2.6, 1.1);
                    break;
                case "sv": Nordic(g, "#005293", "#FECB00", 4); break;
                default:
                    Box(g, "#012169", 0, 0, 30, 20);
                    Slash(g, "#FFFFFF", 4.4, 0, 0, 30, 20);
                    Slash(g, "#FFFFFF", 4.4, 30, 0, 0, 20);
                    Slash(g, "#C8102E", 2.0, 0, 0, 30, 20);
                    Slash(g, "#C8102E", 2.0, 30, 0, 0, 20);
                    Box(g, "#FFFFFF", 12, 0, 6, 20);
                    Box(g, "#FFFFFF", 0, 7, 30, 6);
                    Box(g, "#C8102E", 13.5, 0, 3, 20);
                    Box(g, "#C8102E", 0, 8.5, 30, 3);
                    break;
            }
        }
    }
}
